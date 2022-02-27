//
/*-
 * ---license-start
 * eu-digital-green-certificates / dgca-wallet-app-ios
 * ---
 * Copyright (C) 2021 T-Systems International GmbH and all other contributors
 * ---
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ---license-end
 */
//  
//  GatewayConnection.swift
//  DGCAWallet
//  
//  Created by Yannick Spreen on 5/3/21.
//  

import UIKit
import Alamofire
import SwiftDGC
import SwiftyJSON
import CertLogic
import JWTDecode

enum GatewayError: Error {
    case insufficientData
    case encodingError
    case signingError
    case updatingError
    case incorrectDataResponse
    case connection(error: Error)
    case local(description: String)
    case parsingError
    case privateKeyError
    case tokenError
}

typealias ValueSetsCompletion = ([ValueSet]?, Error?) -> Void
typealias ValueSetCompletionHandler = (ValueSet?, Error?) -> Void
typealias RulesCompletion = ([Rule]?, Error?) -> Void
typealias RuleCompletionHandler = (Rule?, Error?) -> Void
typealias CountriesCompletion = ([CountryModel]?, Error?) -> Void
typealias TicketingCompletion = (AccessTokenResponse?, Error?) -> Void
typealias ContextCompletion = (Bool, String?, Error?) -> Void

class GatewayConnection: ContextConnection {
    static func claim(cert: HCert, with tan: String?, completion: @escaping ContextCompletion) {
        guard var tan = tan, !tan.isEmpty else {
            completion(false, nil, GatewayError.insufficientData)
            return
        }
        
        // Replace dashes, spaces, etc. and turn into uppercase.
        let set = CharacterSet(charactersIn: "0123456789").union(.uppercaseLetters)
        tan = tan.uppercased().components(separatedBy: set.inverted).joined()
        
        let tanHash = SHA256.stringDigest(input: Data(tan.data(using: .utf8) ?? .init()))
        let certHash = cert.certHash
        let pubKey = (X509.derPubKey(for: cert.keyPair) ?? Data()).base64EncodedString()
        
        let toBeSigned = tanHash + certHash + pubKey
        let toBeSignedData = Data(toBeSigned.data(using: .utf8) ?? .init())
        
        Enclave.sign(data: toBeSignedData, with: cert.keyPair, using: .ecdsaSignatureMessageX962SHA256) { sign, err in
            guard err == nil else {
                completion(false, nil, GatewayError.local(description: err!))
                return
            }
            guard let sign = sign else {
                completion(false, nil, GatewayError.local(description: "No sign"))
                return
            }
            let keyParam: [String: Any] = [ "type": "EC", "value": pubKey ]
            let param: [String: Any] = [
                "DGCI": cert.uvci,
                "TANHash": tanHash,
                "certhash": certHash,
                "publicKey": keyParam,
                "signature": sign.base64EncodedString(),
                "sigAlg": "SHA256withECDSA"
            ]
            request( ["endpoints", "claim"], method: .post, parameters: param, encoding: JSONEncoding.default,
                     headers: HTTPHeaders([HTTPHeader(name: "content-type", value: "application/json")])).response {
                guard case .success(_) = $0.result, let status = $0.response?.statusCode, status / 100 == 2 else {
                    completion(false, nil, GatewayError.local(description: "Cannot claim certificate"))
                    return
                }
                let response = String(data: $0.data ?? .init(), encoding: .utf8)
                let json = JSON(parseJSON: response ?? "")
                let newTAN = json["tan"].string
                completion(true, newTAN, nil)
            }
        }
    }
    
    static func lookup(certStrings: [DatedCertString], completion: @escaping ContextCompletion) {
        // construct certs from strings
        var certs: [Date:HCert] = [:]
        for string in certStrings {
            guard let c = string.cert else { completion(false, nil, nil); return; }
            certs[string.date] = c
        }
        var certHashes: [String] = []
        certs.forEach { _, cert in
            certHashes.append(cert.certHash)
        }
        let param: [String: Any] = ["value": certHashes]
        request(
            [""],
            externalLink: "https://dgca-revocation-service-eu-test.cfapps.eu10.hana.ondemand.com/revocation/lookup",
            method: .post,
            parameters: param,
            encoding: JSONEncoding.default
        ).response {
            guard
                case .success(_) = $0.result,
                let status = $0.response?.statusCode,
                let response = String(data: $0.data ?? .init(), encoding: .utf8),
                status / 100 == 2
            else {
                completion(false, nil, nil)
                return
            }
            if response.count == 0 { completion(true, nil, nil); return }
            // response is list of hashes that have been revoked
            let revokedHashes = certHashes.filter { element in
                return !response.contains(element)
            }
            for revokedHash in revokedHashes {
                certs.forEach { date, cert in
                    if cert.certHash.elementsEqual(revokedHash) {
                        cert.isRevoked = true
                        // remove old certificate and add new
                        DataCenter.localDataManager.remove(withDate: date) { status in
                            guard case .success(_) = status else { completion(false, nil, nil); return }
                            var storedTan: String?
                            certStrings.forEach { certString in
                                if certString.cert!.certHash.elementsEqual(cert.certHash) {
                                    storedTan = certString.storedTAN ?? nil
                                }
                            }
                            DataCenter.localDataManager.add(cert, with: storedTan) { status in
                                guard case .success(_) = status else { completion(false, nil, nil); return }
                            }
                        }
                    }
                }
            }
            completion(true, nil, nil)
        }
    }
    
    static func fetchContext(completion: @escaping CompletionHandler) {
        request( ["context"] ).response {
            guard let data = $0.data, let string = String(data: data, encoding: .utf8) else { return }
            
            let json = JSON(parseJSONC: string)
            DataCenter.localDataManager.localData.config.merge(other: json)
            DataCenter.localDataManager.save { result in
                if DataCenter.localDataManager.versionedConfig["outdated"].bool == true {
                    let controller = UIApplication.shared.windows.first?.rootViewController as? UINavigationController
                    controller?.popToRootViewController(animated: false)
                }
                completion()
            }
        }
    }
    
    static var config: JSON {
        return DataCenter.localDataManager.versionedConfig
    }
}

// MARK: Country, Rules, Valuesets extension
extension GatewayConnection {
    // Country list
    private static func getListOfCountry(completion: @escaping CountriesCompletion) {
        request(["endpoints", "countryList"], method: .get).response {
            guard case let .success(result) = $0.result, let response = result,
                  let responseStr = String(data: response, encoding: .utf8),
                  let json = JSON(parseJSON: responseStr).array else {
                      completion(nil, GatewayError.parsingError)
                      return
                  }
            let codes = json.compactMap { $0.string }
            var countryList: [CountryModel] = []
            codes.forEach { code in
                countryList.append(CountryModel(code: code))
            }
            completion(countryList, nil)
        }
    }
    
    static func loadCountryList(completion: @escaping CountriesCompletion) {
        getListOfCountry { list, error in
            guard error == nil else {
                completion(nil, GatewayError.connection(error: error!))
                return
            }
            guard let countryCodeList = list else {
                completion(nil, GatewayError.local(description: "No sign"))
                return
            }
            DataCenter.addCountries(countryCodeList)
            let countryCodes = DataCenter.countryCodes.sorted(by: { $0.name < $1.name })
            completion(countryCodes, nil)
        }
    }
    
    // Rules
    static func getListOfRules(completion: @escaping RulesCompletion) {
        request(["endpoints", "rules"], method: .get).response {
            guard case let .success(result) = $0.result, let response = result,
                  let responseStr = String(data: response, encoding: .utf8)
            else {
                completion(nil, GatewayError.parsingError)
                return
            }
            let ruleHashes: [RuleHash] = CertLogicEngine.getItems(from: responseStr)
            // Remove old hashes
            DataCenter.rules = DataCenter.rules.filter { rule in
                return !ruleHashes.contains(where: { $0.hash == rule.hash})
            }
            
            // Downloading new hashes
            let rulesItems = SyncArray<Rule>()
            let group = DispatchGroup()
            ruleHashes.forEach { ruleHash in
                group.enter()
                if !DataCenter.localDataManager.isRuleExistWithHash(hash: ruleHash.hash) {
                    getRules(ruleHash: ruleHash) { rule, error in
                        guard error == nil else {
                            completion(nil, GatewayError.connection(error: error!))
                            return
                        }
                        guard let rule = rule else {
                            completion(nil, GatewayError.parsingError)
                            return
                        }
                        rulesItems.append(rule)
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                completion(rulesItems.resultArray, nil)
                DGCLogger.logInfo("Finished all Rules requests.")
            }
        }
    }
    
    static func getRules(ruleHash: RuleHash, completion: @escaping RuleCompletionHandler) {
        request(["endpoints", "rules"], externalLink: "/\(ruleHash.country)/\(ruleHash.hash)", method: .get).response {
            guard case let .success(result) = $0.result,
                  let response = result,
                  let responseStr = String(data: response, encoding: .utf8)
            else {
                completion(nil, GatewayError.parsingError)
                return
            }
            if var rule: Rule = CertLogicEngine.getItem(from: responseStr) {
                let downloadedRuleHash = SHA256.digest(input: response as NSData)
                if downloadedRuleHash.hexString == ruleHash.hash {
                    rule.setHash(hash: ruleHash.hash)
                    completion(rule, nil)
                } else {
                    completion(nil, GatewayError.signingError)
                }
                return
            } else {
                completion(nil, GatewayError.signingError)
            }
        }
    }
    
    static func loadRulesFromServer(completion: @escaping RulesCompletion) {
        getListOfRules { rulesList, error in
            guard error == nil else {
                completion(nil, GatewayError.connection(error: error!))
                return
            }
            guard let rules = rulesList else {
                completion(nil, GatewayError.parsingError)
                return
            }
            DataCenter.addRules(rules)
            completion(DataCenter.rules, nil)
        }
    }
    
    // ValueSets
    static func getListOfValueSets(completion: @escaping ValueSetsCompletion) {
        request(["endpoints", "valuesets"], method: .get).response {
            guard case let .success(result) = $0.result, let response = result,
                  let responseStr = String(data: response, encoding: .utf8)
            else {
                completion(nil, GatewayError.parsingError)
                return
            }
            let valueSetsHashes: [ValueSetHash] = CertLogicEngine.getItems(from: responseStr)
            // Remove old hashes
            DataCenter.valueSets = DataCenter.valueSets.filter { valueSet in
                return !valueSetsHashes.contains(where: { $0.hash == valueSet.hash})
            }
            // Downloading new hashes
            let valueSetsItems = SyncArray<ValueSet>()
            let group = DispatchGroup()
            valueSetsHashes.forEach { valueSetHash in
                group.enter()
                if !DataCenter.localDataManager.isValueSetExistWithHash(hash: valueSetHash.hash) {
                    loadValueSet(valueSetHash: valueSetHash) { valueSet, error in
                        guard error == nil else {
                            completion(nil, GatewayError.connection(error: error!))
                            return
                        }
                        if let valueSet = valueSet {
                            valueSetsItems.append(valueSet)
                        }
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                completion(valueSetsItems.resultArray, nil)
                DGCLogger.logInfo("Finished all ValueSets requests.")
            }
        }
    }
    
    static private func loadValueSet(valueSetHash: ValueSetHash, completion: @escaping ValueSetCompletionHandler) {
        request(["endpoints", "valuesets"], externalLink: "/\(valueSetHash.hash)", method: .get).response {
            guard case let .success(result) = $0.result, let response = result,
                  let responseStr = String(data: response, encoding: .utf8)
            else {
                completion(nil, GatewayError.parsingError)
                return
            }
            guard var valueSet: ValueSet = CertLogicEngine.getItem(from: responseStr) else {
                completion(nil, GatewayError.encodingError)
                return
            }
            let downloadedValueSetHash = SHA256.digest(input: response as NSData)
            if downloadedValueSetHash.hexString == valueSetHash.hash {
                valueSet.setHash(hash: valueSetHash.hash)
                completion(valueSet, nil)
            } else {
                completion(nil, GatewayError.signingError)
            }
        }
    }
    
    static func loadValueSetsFromServer(completion: @escaping ValueSetsCompletion) {
        getListOfValueSets { list, error in
            guard error == nil else {
                completion(nil, GatewayError.connection(error: error!))
                return
            }
            guard let valueSetsList = list else {
                completion(nil, GatewayError.connection(error: error!))
                return
            }
            
            DataCenter.addValueSets(valueSetsList)
            completion(DataCenter.valueSets, nil)
        }
    }
    
    static func loadAccessToken(_ url : URL, servicePath : String, publicKey: String, completion: @escaping TicketingCompletion) {
        let json: [String: Any] = ["service": servicePath, "pubKey": publicKey]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json,options: .prettyPrinted),
              let tokenData = KeyChain.load(key: SharedConstants.keyTicketingToken)  else {
                  completion(nil, GatewayError.tokenError)
                  return
              }
        let token = String(decoding: tokenData, as: UTF8.self)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue( "1.0.0", forHTTPHeaderField: "X-Version")
        request.addValue( "application/json", forHTTPHeaderField: "content-type")
        request.addValue( "Bearer " + token, forHTTPHeaderField: "Authorization")
        
        let session = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            guard error == nil else {
                completion(nil, GatewayError.connection(error: error!))
                return
            }
            guard let responseData = data, let tokenJWT = String(data: responseData, encoding: .utf8), responseData.count > 0 else {
                completion(nil, GatewayError.incorrectDataResponse)
                return
            }
            do {
                let decodedToken = try decode(jwt: tokenJWT)
                let jsonData = try JSONSerialization.data(withJSONObject: decodedToken.body)
                let accessTokenResponse = try JSONDecoder().decode(AccessTokenResponse.self, from: jsonData)
                
                if let tokenData = tokenJWT.data(using: .utf8) {
                    KeyChain.save(key: SharedConstants.keyAccessToken, data: tokenData)
                }
                if let httpResponse = response as? HTTPURLResponse,
                   let xnonceData = (httpResponse.allHeaderFields["x-nonce"] as? String)?.data(using: .utf8) {
                    KeyChain.save(key: SharedConstants.keyXnonce, data: xnonceData)
                }
                completion(accessTokenResponse, nil)
                
            } catch {
                completion(nil, GatewayError.encodingError)
                DGCLogger.logError(error)
            }
        })
        session.resume()
    }
    
    static func validateTicketing(url : URL, parameters : [String: String]?, completion : @escaping TicketingCompletion) {
        guard let parametersData = try? JSONEncoder().encode(parameters) else {
            completion(nil, GatewayError.encodingError)
            return
        }
        guard let tokenData = KeyChain.load(key: SharedConstants.keyAccessToken) else {
            completion(nil, GatewayError.tokenError)
            return
        }
        let token = String(decoding: tokenData, as: UTF8.self)
        var request = URLRequest(url: url)
        request.method = .post
        request.httpBody = parametersData
        
        request.addValue( "1.0.0", forHTTPHeaderField: "X-Version")
        request.addValue( "application/json", forHTTPHeaderField: "content-type")
        request.addValue( "Bearer " + token, forHTTPHeaderField: "Authorization")
        
        let session = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            guard error == nil else {
                completion(nil,GatewayError.connection(error: error!))
                return
            }
            guard let responseData = data, let tokenJWT = String(data: responseData, encoding: .utf8) else {
                completion(nil, GatewayError.incorrectDataResponse)
                return
            }
            do {
                let decodedToken = try decode(jwt: tokenJWT)
                let jsonData = try JSONSerialization.data(withJSONObject: decodedToken.body)
                let decoder = JSONDecoder()
                let accessTokenResponse = try decoder.decode(AccessTokenResponse.self, from: jsonData)
                completion(accessTokenResponse, nil)
                
            } catch {
                completion(nil, GatewayError.parsingError)
                DGCLogger.logError(error)
            }
        })
        session.resume()
    }
}
