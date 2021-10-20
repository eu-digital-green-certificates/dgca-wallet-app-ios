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
//  QRTicketCodeDetailsViewController.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 16.09.2021.
//  


import UIKit
import SwiftDGC
import CryptoSwift

class TicketCodeAcceptViewController: UIViewController {
  
  @IBOutlet weak var certificateTitle: UILabel!
  @IBOutlet weak var validToLabel: UILabel!
  @IBOutlet weak var consetsLabel: UILabel!
  @IBOutlet weak var infoLabel: UILabel!
  
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var grandButton: UIButton!
  
  private var validationServiceInfo : ServerListResponse?
  private var accessTokenInfo       : AccessTokenResponse?
  private var cert                  : HCert?
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  private func setuppView(isValidation: Bool) {
    if isValidation {
      certificateTitle.text = "Vaccination 1 of 1"
      validToLabel.text = "No expiration date"
      consetsLabel.text = "Consent"
      infoLabel.text = "Do you agree share the vaccination certificate 2 with Airline.com?"
    }
  }
  
  public func setCertsWith(_ validationInfo: ServerListResponse,_ accessTokenModel : AccessTokenResponse,_ certificate : HCert) {
    validationServiceInfo = validationInfo
    accessTokenInfo = accessTokenModel
    cert = certificate
    setuppView(isValidation: true)
  }
  
  @IBAction func cancelButtonAction(_ sender: Any) {
    dismiss(animated: true, completion: nil)
  }
  
  @IBAction func grandButtonAction(_ sender: Any) {
    
    guard let urlPath = accessTokenInfo?.aud!,
          let url = URL(string: urlPath),
          let iv = UserDefaults.standard.object(forKey: "xnonce"),
          let verificationMethod = validationServiceInfo!.verificationMethod!.first(where: { $0.publicKeyJwk?.use == "enc" }),
          let dccData = encodeDCC(dgcString: cert!.fullPayloadString, iv: iv as! String),
          let privateKey = Enclave.loadOrGenerateKey(with: "validationKey")
    else { return }
    
    var sig = Data()
    
    Enclave.sign(data: dccData.0, with: privateKey, using: SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256, completion: { (signature,error) in
      if let sign = signature {
       sig = sign
        let parameters = ["kid" : verificationMethod.publicKeyJwk!.kid, "dcc" : dccData.0.base64EncodedString(), "sig": sig.base64EncodedString(),"encKey" : dccData.1.base64EncodedString(), "sigAlg" : "SHA256withECDSA", "encScheme" : "RSAOAEPWithSHA256AESGCM"]
        
        GatewayConnection.validateTicketing(url: url, parameters: parameters) { resultStr in
          print(resultStr)
        }
      }
    })
    
    
  }
  
  func encodeDCC(dgcString : String, iv: String) -> (Data,Data)? {
    guard (iv.count > 16 || iv.count < 16 || iv.count % 8 > 0) else { return nil }
    guard let verificationMethod = validationServiceInfo!.verificationMethod!.first(where: { $0.publicKeyJwk?.use == "enc" }) else { return nil }
    
    let ivData : [UInt8] = Array(base64: iv)
    let dgcData : [UInt8] = Array(dgcString.utf8)
    
    let publicKeyData : [UInt8] = Array(base64: verificationMethod.publicKeyJwk!.x5c)
    
    var encryptedDgcData : [UInt8] = Array()
    
    // AES GCM
    
    let password: [UInt8] = Array("s33krit".utf8)
    let salt: [UInt8] = Array("nacllcan".utf8)

    /* Generate a key from a `password`. Optional if you already have a key */
    let key = try! PKCS5.PBKDF2(
        password: password,
        salt: salt,
        iterations: 4096,
        keyLength: 32, /* AES-256 */
        variant: .sha2(.sha256)
    ).calculate()

    let publicSecKey = TicketCodeAcceptViewController.pubKey(from: verificationMethod.publicKeyJwk!.x5c)
    
    do {
      
        let gcm = GCM(iv: ivData, mode: .combined)
        let aes = try AES(key: key, blockMode: gcm, padding: .noPadding)
        encryptedDgcData = try aes.encrypt(dgcData)
//        let tag = gcm.authenticationTag
      
    } catch {
        // failed
    }
    
    let errorEncr : UnsafeMutablePointer<Unmanaged<CFError>?>? = nil
    let encryptedKeyData = TicketCodeAcceptViewController.encrypt(data: Data(key), with: publicSecKey!)
    
    return (Data(encryptedDgcData),encryptedKeyData.0!)
  }
  
  static func encrypt(data: Data, with key: SecKey) -> (Data?, String?) {
    guard let publicKey = SecKeyCopyPublicKey(key) else {
      return (nil, l10n("err.pub-key-irretrievable"))
    }
    guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, SecKeyAlgorithm.rsaEncryptionOAEPSHA256) else {
      return (nil, l10n("err.alg-not-supported"))
    }
    var error: Unmanaged<CFError>?
    let cipherData = SecKeyCreateEncryptedData(
      publicKey,
      SecKeyAlgorithm.rsaEncryptionOAEPSHA256,
      data as CFData,
      &error
    ) as Data?
    let err = error?.takeRetainedValue().localizedDescription
    return (cipherData, err)
  }
  
  func keyFromData(_ data: Data) throws -> SecKey {
    
    
    let options: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                  kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
                                  kSecAttrKeySizeInBits as String : 4096]
    
    var error: Unmanaged<CFError>?
    guard let key = SecKeyCreateWithData(data as CFData,
                                         options as CFDictionary,
                                         &error) else {
                                            throw error!.takeRetainedValue() as Error
    }
    return key
  }
  
  public static func pubKey(from b64EncodedCert: String) -> SecKey? {
      guard
        let encodedCertData = Data(base64Encoded: b64EncodedCert),
        let cert = SecCertificateCreateWithData(nil, encodedCertData as CFData),
        let publicKey = SecCertificateCopyKey(cert)
      else {
        return nil
      }
      return publicKey
  }
  
}

