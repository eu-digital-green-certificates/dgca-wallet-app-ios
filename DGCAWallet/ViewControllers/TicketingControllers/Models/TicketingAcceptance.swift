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
//  TicketingAcceptance.swift
//  DGCAWallet
//  
//  Created by Igor Khomiak on 17.11.2021.
//  
        

import UIKit
import SwiftDGC
import CryptoSwift


struct TicketingAcceptance {
  let validationInfo: ServerListResponse
  let accessInfo : AccessTokenResponse

  var certificateRecords: [CertificateRecord] {
    guard let vcValue = accessInfo.vc else { return [] }
    var records = [CertificateRecord]()
    records.append(CertificateRecord(keyName: "Name".localized, value: "\(vcValue.gnt) \(vcValue.fnt)"))
    records.append(CertificateRecord(keyName: "Date of birth".localized, value: vcValue.dob))
    records.append(CertificateRecord(keyName: "Departure".localized, value: "\(vcValue.cod),\(vcValue.rod)"))
    records.append(CertificateRecord(keyName: "Arrival".localized, value:  "\(vcValue.coa),\(vcValue.roa)"))
    records.append(CertificateRecord(keyName: "Accepted certificate type".localized, value: vcValue.type.joined(separator: ",")))
    records.append(CertificateRecord(keyName: "Category".localized, value: vcValue.category.joined(separator: ",")))
    records.append(CertificateRecord(keyName: "Validation Time".localized, value: vcValue.validationClock))
    records.append(CertificateRecord(keyName: "Valid from".localized, value: vcValue.validFrom))
    records.append(CertificateRecord(keyName: "Valid to".localized, value: vcValue.validTo))

    return records
  }
    
  init(validationInfo: ServerListResponse, accessInfo: AccessTokenResponse) {
      self.validationInfo = validationInfo
      self.accessInfo = accessInfo
  }
  
  var ticketingCertificates: [DatedCertString] {
    guard let validationCertificate = self.accessInfo.vc else { return [] }
      let givenName = validationCertificate.gnt
      let familyName = validationCertificate.fnt
    
    var collectArray = DataCenter.certStrings.filter { ($0.cert!.fullName.lowercased() == "\(givenName) \(familyName)".lowercased()) &&
      ($0.cert!.dateOfBirth == validationCertificate.dob) }
    
    let validDateFrom = validationCertificate.validFrom
    if let dateValidFrom = Date(rfc3339DateTimeString: validDateFrom) {
      collectArray = collectArray.filter{ $0.cert!.iat < dateValidFrom }
    }
    
    let validDateTo = validationCertificate.validTo
    if let dateValidUntil = Date(rfc3339DateTimeString: validDateTo) {
      collectArray = collectArray.filter {$0.cert!.exp > dateValidUntil }
    }
    return collectArray
  }
  
  func requestGrandPermissions(for certificate: HCert, completion: @escaping TicketingCompletion) {
    guard let urlPath = self.accessInfo.aud, let url = URL(string: urlPath) else { completion(nil, GatewayError.insufficientData); return }
    guard let tokenData = KeyChain.load(key: SharedConstants.keyXnonce) else { completion(nil, GatewayError.tokenError); return }
    guard let privateKey = Enclave.loadOrGenerateKey(with: "validationKey") else { completion(nil, GatewayError.privateKeyError); return }

    guard let filteredMethod = (validationInfo.verificationMethod?.filter {
        $0.publicKeyJwk?.use == "enc" &&
        $0.type == ValidationConstants.dccEncryptionScheme2021 &&
        $0.id.hasSuffix(ValidationConstants.rsaOAEPWithSHA256AESGCM)
    })?.last
    else { completion(nil, GatewayError.insufficientData); return }

    guard let verificationMethod = validationInfo.verificationMethod?.first(where: { $0.id == filteredMethod.id })
    else { completion(nil, GatewayError.insufficientData); return }


    let ivToken = String(decoding: tokenData, as: UTF8.self)

    encodeDCC(dgcString: certificate.fullPayloadString, token: ivToken, method: verificationMethod) { data, error in
      guard error == nil else { completion(nil, GatewayError.local(description: error!.localizedDescription)); return }
      guard let dccData = data else { completion(nil, GatewayError.local(description: "EncodeDCC Error")); return }

      Enclave.sign(data: dccData.0, with: privateKey, using: SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256, completion: { (signature, error) in
        guard error == nil else { completion(nil, GatewayError.local(description: error!)); return }
        guard let sign = signature else { completion(nil, GatewayError.signingError); return }
        
        let parameters = ["kid" : verificationMethod.publicKeyJwk!.kid,
            "dcc" : dccData.0.base64EncodedString(),
            "sig": sign.base64EncodedString(),
            "encKey" : dccData.1.base64EncodedString(),
            "sigAlg" : ValidationConstants.sha256withECDSA,
            "encScheme" : ValidationConstants.rsaOAEPWithSHA256AESGCM]
        
        GatewayConnection.validateTicketing(url: url, parameters: parameters, completion: completion)
      })
    }
  }

  private func encodeDCC(dgcString : String, token: String, method: VerificationMethod, completion: @escaping EncodingCompletion) {
    guard (token.count > 16 || token.count < 16 || token.count % 8 > 0),
        let b64EncodedCert = method.publicKeyJwk?.x5c.first,
        let publicSecKey = pubKey(from: b64EncodedCert)
    else { completion(nil, EncodeError.incorrectPayload); return }

    let tokenData : [UInt8] = Array(base64: token)
    let dgcData : [UInt8] = Array(dgcString.utf8)
    var encryptedDgcData : [UInt8] = Array()
    
    // AES GCM
    let password: [UInt8] = Array("s33krit".utf8)
    let salt: [UInt8] = Array("nacllcan".utf8)

    do {
      /* Generate a key from a `password`. Optional if you already have a key */
      let key = try PKCS5.PBKDF2(password: password, salt: salt, iterations: 4096, keyLength: 32, /* AES-256 */
          variant: .sha2(.sha256)).calculate()

      let gcm = GCM(iv: tokenData, mode: .combined)
      let aes = try AES(key: key, blockMode: gcm, padding: .noPadding)
      encryptedDgcData = try aes.encrypt(dgcData)
      if let encryptedData = encrypt(data: Data(key), with: publicSecKey).0 {
        let comletionData = (Data(encryptedDgcData), encryptedData)
        completion(comletionData, nil)
      } else {
        DGCLogger.logError(EncodeError.encryptionData)
        completion(nil, EncodeError.encryptionData)
      }
      
    } catch {
      DGCLogger.logError(error)
      completion(nil, EncodeError.encryptionData)
    }
  }
  
  private func encrypt(data: Data, with key: SecKey) -> (Data?, String?) {
    guard let publicKey = SecKeyCopyPublicKey(key) else { return (nil, "Cannot retrieve public key.".localized) }
    guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, SecKeyAlgorithm.rsaEncryptionOAEPSHA256) else {
      return (nil, "Algorithm is not supported.".localized)
    }
    var error: Unmanaged<CFError>?
    let cipherData = SecKeyCreateEncryptedData(publicKey,
        SecKeyAlgorithm.rsaEncryptionOAEPSHA256, data as CFData, &error) as Data?
    let err = error?.takeRetainedValue().localizedDescription
    return (cipherData, err)
  }
  
  private func keyFromData(_ data: Data) throws -> SecKey {
    let options: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
      kSecAttrKeyClass as String: kSecAttrKeyClassPublic, kSecAttrKeySizeInBits as String : 4096]
    
    var error: Unmanaged<CFError>?
    
    guard let key = SecKeyCreateWithData(data as CFData, options as CFDictionary, &error)
    else { throw error!.takeRetainedValue() as Error }
    return key
  }

  private func pubKey(from b64EncodedCert: String) -> SecKey? {
      guard let encodedCertData = Data(base64Encoded: b64EncodedCert),
        let cert = SecCertificateCreateWithData(nil, encodedCertData as CFData),
        let publicKey = SecCertificateCopyKey(cert)
      else { return nil }
      return publicKey
  }
}
