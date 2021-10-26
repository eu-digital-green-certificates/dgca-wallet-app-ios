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

import Foundation
import Alamofire
import SwiftDGC
import SwiftyJSON
import UIKit
import CertLogic
import CryptoKit
import SwiftUI
import JWTDecode
import CryptoSwift

struct GatewayConnection: ContextConnection {
  public static func claim(cert: HCert, with tan: String?, completion: ((Bool, String?) -> Void)?) {
    guard var tan = tan, !tan.isEmpty else { return }
      
    // Replace dashes, spaces, etc. and turn into uppercase.
    let set = CharacterSet(charactersIn: "0123456789").union(.uppercaseLetters)
    tan = tan.uppercased().components(separatedBy: set.inverted).joined()
    
    let tanHash = SHA256.stringDigest(input: Data(tan.data(using: .utf8) ?? .init()))
    let certHash = cert.certHash
    let pubKey = (X509.derPubKey(for: cert.keyPair) ?? Data()).base64EncodedString()
    
    let toBeSigned = tanHash + certHash + pubKey
    let toBeSignedData = Data(toBeSigned.data(using: .utf8) ?? .init())
    Enclave.sign(data: toBeSignedData, with: cert.keyPair, using: .ecdsaSignatureMessageX962SHA256) { sign, err in
      guard let sign = sign, err == nil else { return }
      
      let keyParam: [String: Any] = [ "type": "EC", "value": pubKey ]
      let param: [String: Any] = [
        "DGCI": cert.uvci,
        "TANHash": tanHash,
        "certhash": certHash,
        "publicKey": keyParam,
        "signature": sign.base64EncodedString(),
        "sigAlg": "SHA256withECDSA"
      ]
    print("\nAlamofire -----------------------------------------------------")
    print("Alamofire - param: \(param)")
        
      request(
        ["endpoints", "claim"],
        method: .post,
        parameters: param,
        encoding: JSONEncoding.default).response {
        guard case .success(_) = $0.result,
          let status = $0.response?.statusCode,
          status / 100 == 2
        else {
          completion?(false, nil)
          return
        }
        
        let response = String(data: $0.data ?? .init(), encoding: .utf8)
        let json = JSON(parseJSON: response ?? "")
        let newTAN = json["tan"].string
        completion?(true, newTAN)
      }
    }
  }
  
  public static func fetchContext() {
    request( ["context"] ).response {
      guard let data = $0.data, let string = String(data: data, encoding: .utf8) else { return }
        
      let json = JSON(parseJSONC: string)
      LocalData.sharedInstance.config.merge(other: json)
      LocalData.sharedInstance.save()
      if LocalData.sharedInstance.versionedConfig["outdated"].bool == true {
        let controller = UIApplication.shared.windows[0].rootViewController as? UINavigationController
        controller?.popToRootViewController(animated: false)
      }
    }
  }
  static var config: JSON {
    LocalData.sharedInstance.versionedConfig
  }
}

// MARK: Country, Rules, Valuesets extension

extension GatewayConnection {
  // Country list
  public static func getListOfCountry(completion: (([CountryModel]) -> Void)?) {
    request(["endpoints", "countryList"], method: .get).response {
      guard case let .success(result) = $0.result,
        let response = result,
        let responseStr = String(data: response, encoding: .utf8),
        let json = JSON(parseJSON: responseStr).array
      else { return }
        
      let codes = json.compactMap { $0.string }
      var countryList: [CountryModel] = []
      codes.forEach { code in
        countryList.append(CountryModel(code: code))
      }
      completion?(countryList)
    }
  }
    
  static func countryList(completion: (([CountryModel]) -> Void)? = nil) {
    CountryDataStorage.initialize {
      if CountryDataStorage.sharedInstance.countryCodes.count > 0 {
        completion?(CountryDataStorage.sharedInstance.countryCodes.sorted(by: { $0.name < $1.name }))
      }
      getListOfCountry { countryList in
        CountryDataStorage.sharedInstance.countryCodes.removeAll()
        countryList.forEach { country in
          CountryDataStorage.sharedInstance.add(country: country)
        }
        CountryDataStorage.sharedInstance.lastFetch = Date()
        CountryDataStorage.sharedInstance.save()
          completion?(CountryDataStorage.sharedInstance.countryCodes.sorted(by: { $0.name < $1.name }))
      }
    }
  }
    
  // Rules
  public static func getListOfRules(completion: (([CertLogic.Rule]) -> Void)?) {
    request(["endpoints", "rules"], method: .get).response {
      guard case let .success(result) = $0.result,
        let response = result,
        let responseStr = String(data: response, encoding: .utf8)
      else { return }
        
      let ruleHashes: [RuleHash] = CertLogicEngine.getItems(from: responseStr)
      // Remove old hashes
      RulesDataStorage.sharedInstance.rules = RulesDataStorage.sharedInstance.rules.filter { rule in
          return !ruleHashes.contains(where: { $0.hash == rule.hash})
      }
      // Downloading new hashes
      var rulesItems = [CertLogic.Rule]()
      let downloadingGroup = DispatchGroup()
      ruleHashes.forEach { ruleHash in
        downloadingGroup.enter()
        if !RulesDataStorage.sharedInstance.isRuleExistWithHash(hash: ruleHash.hash) {
          getRules(ruleHash: ruleHash) { rule in
            if let rule = rule {
              rulesItems.append(rule)
            }
            downloadingGroup.leave()
          }
        } else {
          downloadingGroup.leave()
        }
      }
      downloadingGroup.notify(queue: .main) {
        completion?(rulesItems)
        print("Finished all requests.")
      }
    }
  }
  public static func getRules(ruleHash: CertLogic.RuleHash, completion: ((CertLogic.Rule?) -> Void)?) {
    request(["endpoints", "rules"], externalLink: "/\(ruleHash.country)/\(ruleHash.hash)", method: .get).response {
      guard case let .success(result) = $0.result,
        let response = result,
        let responseStr = String(data: response, encoding: .utf8)
      else {
        completion?(nil)
        return
      }
      if let rule: Rule = CertLogicEngine.getItem(from: responseStr) {
        let downloadedRuleHash = SHA256.digest(input: response as NSData)
        if downloadedRuleHash.hexString == ruleHash.hash {
          rule.setHash(hash: ruleHash.hash)
          completion?(rule)
        } else {
          completion?(nil)
        }
        return
      }
      completion?(nil)
    }
  }
  static func rulesList(completion: (([CertLogic.Rule]) -> Void)? = nil) {
    RulesDataStorage.initialize {
      completion?(RulesDataStorage.sharedInstance.rules)
    }
  }
  
  static func loadRulesFromServer(completion: (([CertLogic.Rule]) -> Void)? = nil) {
    getListOfRules { rulesList in
      rulesList.forEach { RulesDataStorage.sharedInstance.add(rule: $0) }
      RulesDataStorage.sharedInstance.lastFetch = Date()
      RulesDataStorage.sharedInstance.save()
      completion?(RulesDataStorage.sharedInstance.rules)
    }
  }
  
  // ValueSets
  public static func getListOfValueSets(completion: (([CertLogic.ValueSet]) -> Void)?) {
    request(["endpoints", "valuesets"], method: .get).response {
      guard case let .success(result) = $0.result, let response = result,
        let responseStr = String(data: response, encoding: .utf8)
      else { return }
        
      let valueSetsHashes: [ValueSetHash] = CertLogicEngine.getItems(from: responseStr)
      // Remove old hashes
      ValueSetsDataStorage.sharedInstance.valueSets = ValueSetsDataStorage.sharedInstance.valueSets.filter { valueSet in
        return !valueSetsHashes.contains(where: { $0.hash == valueSet.hash})
      }
      // Downloading new hashes
      var valueSetsItems = [CertLogic.ValueSet]()
      let downloadingGroup = DispatchGroup()
      valueSetsHashes.forEach { valueSetHash in
        downloadingGroup.enter()
        if !ValueSetsDataStorage.sharedInstance.isValueSetExistWithHash(hash: valueSetHash.hash) {
          getValueSets(valueSetHash: valueSetHash) { valueSet in
            if let valueSet = valueSet {
              valueSetsItems.append(valueSet)
            }
            downloadingGroup.leave()
          }
        } else {
          downloadingGroup.leave()
        }
      }
      downloadingGroup.notify(queue: .main) {
        completion?(valueSetsItems)
        print("Finished all requests.")
      }
    }
  }
  public static func getValueSets(valueSetHash: CertLogic.ValueSetHash, completion: ((CertLogic.ValueSet?) -> Void)?) {
    request(["endpoints", "valuesets"], externalLink: "/\(valueSetHash.hash)", method: .get).response {
      guard case let .success(result) = $0.result,
        let response = result,
        let responseStr = String(data: response, encoding: .utf8)
      else {
        completion?(nil)
        return
      }
      if let valueSet: ValueSet = CertLogicEngine.getItem(from: responseStr) {
        let downloadedValueSetHash = SHA256.digest(input: response as NSData)
        if downloadedValueSetHash.hexString == valueSetHash.hash {
          valueSet.setHash(hash: valueSetHash.hash)
          completion?(valueSet)
        } else {
          completion?(nil)
        }
        return
      }
      completion?(nil)
    }
  }
  static func valueSetsList(completion: (([CertLogic.ValueSet]) -> Void)? = nil) {
    ValueSetsDataStorage.initialize {
      completion?(ValueSetsDataStorage.sharedInstance.valueSets)
    }
  }
  
  static func loadValueSetsFromServer(completion: (([CertLogic.ValueSet]) -> Void)? = nil){
    getListOfValueSets { valueSetsList in
      valueSetsList.forEach { valueSet in
        ValueSetsDataStorage.sharedInstance.add(valueSet: valueSet)
      }
      ValueSetsDataStorage.sharedInstance.lastFetch = Date()
      ValueSetsDataStorage.sharedInstance.save()
      completion?(ValueSetsDataStorage.sharedInstance.valueSets)
    }
  }

//  static func requestListOfServices(ticketingInfo : CheckInQR, completion : @escaping ((ServerListResponse?) -> Void)) {
//    UserDefaults.standard.set(ticketingInfo.token, forKey: "TicketingToken")
//    let headers = HTTPHeaders([HTTPHeader(name: "X-Version", value: "1.0.0"),HTTPHeader(name: "content-type", value: "application/json")])
//
//    let url = URL(string: ticketingInfo.serviceIdentity)!
//    var request = URLRequest(url: url)
//    request.headers = headers
//
//    let decoder = JSONDecoder()
//    let session = URLSession.shared.dataTask(with: request, completionHandler: { data,response,error in
//      if let responseData = data {
//        let responseModel = try! decoder.decode(ServerListResponse.self, from: responseData)
//        completion(responseModel)
//      } else {
//        completion(nil)
//      }
//    })
//    session.resume()
//  }
//
//  static func getServiceInfo(url : URL, completion: @escaping (ServerListResponse?) -> Void) {
//    let headers = HTTPHeaders([HTTPHeader(name: "X-Version", value: "1.0.0"),HTTPHeader(name: "content-type", value: "application/json")])
//    var request = URLRequest(url: url)
//    request.headers = headers
//
//    let session = URLSession.shared.dataTask(with: request, completionHandler: { data,response,error in
//      guard let data = data else {
//        completion(nil)
//        return
//      }
//      let decoder = JSONDecoder()
//        if let responseModel = try? decoder.decode(ServerListResponse.self, from: data) {
//            completion(responseModel)
//        } else {
//            completion(nil)
//        }
//    })
//    session.resume()
//  }
//=======
//
//>>>>>>> feature/ticketing-reverted
  
  static func getAccessTokenFor(url : URL,servicePath : String, publicKey : String, completion : @escaping (AccessTokenResponse?) -> Void) {
    let json: [String: Any] = ["service": servicePath, "pubKey": publicKey]
    
    let jsonData = try? JSONSerialization.data(withJSONObject: json,options: .prettyPrinted)
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    let token = UserDefaults.standard.object(forKey: "TicketingToken") as! String
    
    request.headers  = [HTTPHeader(name: "Authorization", value: "Bearer " + token),HTTPHeader(name: "X-Version", value: "1.0.0"),HTTPHeader(name: "content-type", value: "application/json")]
    
    let session = URLSession.shared.dataTask(with: request, completionHandler: { data,response,error in
      var accessTokenResponse : AccessTokenResponse?
      
      guard let responseData = data,
            let tokenJWT = String(data: responseData, encoding: .utf8),
            responseData.count > 0 else {
              completion(nil)
              return
            }
      
      guard let decodedToken = try? decode(jwt: tokenJWT),
            let jsonData = try? JSONSerialization.data(withJSONObject: decodedToken.body)
      else {
        completion(nil)
        return
      }
      
      let decoder = JSONDecoder()
      do {
        accessTokenResponse = try decoder.decode(AccessTokenResponse.self, from: jsonData)
      } catch let parseError {
        print(parseError)
      }
      
      if let httpResponse = response as? HTTPURLResponse {
        UserDefaults.standard.set(httpResponse.allHeaderFields["x-nonce"], forKey: "xnonce")
      }
      
      UserDefaults.standard.set(tokenJWT, forKey: "AccessToken")
      completion(accessTokenResponse)
      
    })
    session.resume()
  }
  
  static func validateTicketing(url : URL, parameters : [String: String]?, completion : @escaping (AccessTokenResponse?) -> Void ) {
    var accessTokenResponse : AccessTokenResponse?
    
    let headers = HTTPHeaders([HTTPHeader(name: "Authorization", value: "Bearer " + (UserDefaults.standard.object(forKey: "AccessToken") as! String)),HTTPHeader(name: "X-Version", value: "1.0.0"),HTTPHeader(name: "content-type", value: "application/json")])
    
    let encoder = JSONEncoder()
    guard let parametersData = try? encoder.encode(parameters) else {
      completion(nil)
      return
    }
    
    var request = URLRequest(url: url)
    request.headers = headers
    request.method = .post
    request.httpBody = parametersData
    
    let session = URLSession.shared.dataTask(with: request, completionHandler: { data,response,error in
      
      guard let responseData = data,
            let tokenJWT = String(data: responseData, encoding: .utf8)
      else {
        completion(nil)
        return
      }
      
      guard let decodedToken = try? decode(jwt: tokenJWT),
            let jsonData = try? JSONSerialization.data(withJSONObject: decodedToken.body)
      else {
        completion(nil)
        return
      }
      
      let decoder = JSONDecoder()
      do {
        accessTokenResponse = try decoder.decode(AccessTokenResponse.self, from: jsonData)
      } catch let parseError {
        print(parseError)
      }
      
      completion(accessTokenResponse)
    })
    session.resume()
  }
}
