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

class TicketingAcceptance {
  let validationInfo: ServerListResponse
  let accessInfo : AccessTokenResponse

  let accessTokenInfoKeys = [
    "Name".localized,
    "Date of birth".localized,
    "Departure".localized,
    "Arrival".localized,
    "Accepted certificate type".localized,
    "Category".localized,
    "Validation Time".localized,
    "Valid from".localized,
    "Valid to".localized
  ]

  var accessTokenInfoValues: [String] {
    guard let vcValue = accessInfo.vc else { return [] }
    let infoValueArray = ["\(vcValue.gnt) \(vcValue.fnt)", vcValue.dob, "\(vcValue.cod),\(vcValue.rod)", "\(vcValue.coa),\(vcValue.roa)", vcValue.type.joined(separator: ","), vcValue.category.joined(separator: ","), vcValue.validationClock, vcValue.validFrom, vcValue.validTo]
    return infoValueArray
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
    guard let urlPath = self.accessInfo.aud,
      let url = URL(string: urlPath),
      let verificationMethod = validationInfo.verificationMethod?.first(where: { $0.publicKeyJwk?.use == "enc" })
    else {
      completion(nil, GatewayError.local(description: "Bad input data"))
      return
    }
    
    guard let tokenData = KeyChain.load(key: SharedConstants.keyXnonce) else {
      completion(nil, GatewayError.tokenError)
      return
    }
    let ivToken = String(decoding: tokenData, as: UTF8.self)
    
    guard let dccData = encodeDCC(dgcString: certificate.fullPayloadString, iv: ivToken),
      let privateKey = Enclave.loadOrGenerateKey(with: "validationKey")
    else {
      completion(nil, GatewayError.local(description: "EncodeDCC Error"))
      return
    }
      
    Enclave.sign(data: dccData.0, with: privateKey, using: SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256,
          completion: { (signature, error) in
      guard error == nil else {
        completion(nil, GatewayError.local(description: error!))
        return
      }
      guard let sign = signature else {
        completion(nil, GatewayError.signingError)
        return
      }
      let parameters = ["kid" : verificationMethod.publicKeyJwk!.kid,
          "dcc" : dccData.0.base64EncodedString(),
          "sig": sign.base64EncodedString(),
          "encKey" : dccData.1.base64EncodedString(),
          "sigAlg" : "SHA256withECDSA",
          "encScheme" : "RSAOAEPWithSHA256AESGCM"]
      
      GatewayConnection.validateTicketing(url: url, parameters: parameters, completion: completion)
    })
  }

  private func encodeDCC(dgcString : String, iv: String) -> (Data,Data)? {
    guard (iv.count > 16 || iv.count < 16 || iv.count % 8 > 0) else { return nil }
    guard let verificationMethod = validationInfo.verificationMethod?.first(where: { $0.publicKeyJwk?.use == "enc" })
    else { return nil }
    
    let ivData : [UInt8] = Array(base64: iv)
    let dgcData : [UInt8] = Array(dgcString.utf8)
    let _ : [UInt8] = Array(base64: verificationMethod.publicKeyJwk!.x5c.first!)
    var encryptedDgcData : [UInt8] = Array()
    
    // AES GCM
    let password: [UInt8] = Array("s33krit".utf8)
    let salt: [UInt8] = Array("nacllcan".utf8)

    /* Generate a key from a `password`. Optional if you already have a key */
    let key = try! PKCS5.PBKDF2(password: password, salt: salt, iterations: 4096, keyLength: 32, /* AES-256 */
        variant: .sha2(.sha256)).calculate()

    guard let b64EncodedCert = verificationMethod.publicKeyJwk?.x5c.first else {
      // TODO: complete error
      return nil
    }
    let publicSecKey = pubKey(from: b64EncodedCert)
    do {
      let gcm = GCM(iv: ivData, mode: .combined)
      let aes = try AES(key: key, blockMode: gcm, padding: .noPadding)
      encryptedDgcData = try aes.encrypt(dgcData)
      let encryptedKeyData = encrypt(data: Data(key), with: publicSecKey!)
      return (Data(encryptedDgcData), encryptedKeyData.0!)

    } catch {
      print(error.localizedDescription)
      return nil
    }
  }
    
  private  func encrypt(data: Data, with key: SecKey) -> (Data?, String?) {
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
