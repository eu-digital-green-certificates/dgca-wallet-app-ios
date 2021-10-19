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
    
    Enclave.sign(data: dccData.0, with: privateKey, using: nil, completion: { (signature,error) in
      if let sign = signature {
       sig = sign
        let parameters = [verificationMethod.publicKeyJwk!.kid : "kid", dccData.0.base64EncodedString() :"dcc", sig.base64EncodedString(): "sig",dccData.1.base64EncodedString():"encKey"]
        
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
//    let pubKeyData : [UInt8] = Array(verificationMethod.publicKeyJwk!.x5c.data(using: .utf8)!)
    
    var encryptedDgcData : [UInt8] = Array()
//    var encryptedRSAKey  : [UInt8] = Array()
    
    
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
    
    guard let privateKey = Enclave.loadOrGenerateKey(with: "validationKey") else { return nil }
    
    let publicSecKey = try! keyFromData(Data(publicKeyData))
    
//    var error: Unmanaged<CFError>?
//    guard let privateKeyData = SecKeyCopyExternalRepresentation(privateKey, &error) as Data? else { return nil }
    
    do {
        // In combined mode, the authentication tag is directly appended to the encrypted message. This is usually what you want.
      
        let gcm = GCM(iv: ivData, mode: .combined)
        let aes = try AES(key: key, blockMode: gcm, padding: .noPadding)
        encryptedDgcData = try aes.encrypt(dgcData)
//        encryptedRSAKey = try aes.encrypt(pubKeyData)
        let tag = gcm.authenticationTag
      
    } catch {
        // failed
    }
    
    
    
    let errorEncr : UnsafeMutablePointer<Unmanaged<CFError>?>? = nil
//
    guard let encryptedKeyData:Data = SecKeyCreateEncryptedData(publicSecKey, .rsaEncryptionOAEPSHA256, key as! CFData,errorEncr) as Data? else { return nil }
    
    return (Data(encryptedDgcData),encryptedKeyData)
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
  
  //override fun encryptData(data: ByteArray, publicKey: PublicKey, iv: ByteArray): TicketingEncryptedDgcData {
  //    if (iv.size > 16 || iv.size < 16 || iv.size % 8 > 0) {
  //        throw InvalidKeySpecException()
  //    }
  //    val keyGen: KeyGenerator = KeyGenerator.getInstance("AES")
  //    keyGen.init(256) // for example
  //    val secretKey: SecretKey = keyGen.generateKey()
  //    val gcmParameterSpec = GCMParameterSpec(iv.size * 8, iv)
  //    val cipher: Cipher = Cipher.getInstance(DATA_CIPHER)
  //    cipher.init(Cipher.ENCRYPT_MODE, secretKey, gcmParameterSpec)
  //    val dataEncrypted = cipher.doFinal(data)
  //
  //    // encrypt RSA key
  //    val keyCipher: Cipher = Cipher.getInstance(KEY_CIPHER)
  //    val oaepParameterSpec = OAEPParameterSpec(
  //        "SHA-256", "MGF1", MGF1ParameterSpec.SHA256, PSource.PSpecified.DEFAULT
  //    )
  //    keyCipher.init(Cipher.ENCRYPT_MODE, publicKey, oaepParameterSpec)
  //    val secretKeyBytes: ByteArray = secretKey.encoded
  //    val encKey = keyCipher.doFinal(secretKeyBytes)
  //    return TicketingEncryptedDgcData(dataEncrypted, encKey)
  //}
  
}

//     val ticketingEncryptedDgcData: TicketingEncryptedDgcData = ticketingDgcCryptor.encodeDcc(dgcQrString, iv, publicKey)

//fun provideTicketValidationRequest(
//     dgcQrString: String,
//     kid: String, publicKey: PublicKey,
//     base64EncodedIv: String, privateKey: PrivateKey
// ): ValidateRequest {
//     val iv = Base64.decode(base64EncodedIv, Base64.NO_WRAP)
//     val ticketingEncryptedDgcData: TicketingEncryptedDgcData = ticketingDgcCryptor.encodeDcc(dgcQrString, iv, publicKey)
//     val dcc = Base64.encodeToString(ticketingEncryptedDgcData.dataEncrypted, Base64.NO_WRAP)
//     val encKey = Base64.encodeToString(ticketingEncryptedDgcData.encKey, Base64.NO_WRAP)
//     val sig = ticketingDgcSigner.signDcc(ticketingEncryptedDgcData.dataEncrypted, privateKey)
//     return ValidateRequest(
//         kid = kid,
//         dcc = dcc,
//         sig = sig,
//         encKey = encKey,
//     )
// }

//@Headers(
//    "X-Version: 1.0.0",
//    "content-type: application/json"
//)
//@POST
//suspend fun validate(
//    @Url url: String,
//    @Header("Authorization") authHeader: String,
//    @Body body: ValidateRequest
//): Response<ResponseBody>
//white_check_mark
//eyes
//raised_hands
//React
//Reply
//
//3:55
//data class ValidateRequest(
//@JsonProperty("kid")
//val kid: String,
//@JsonProperty("dcc")
//val dcc: String,
//@JsonProperty("sig")
//val sig: String,
//@JsonProperty("encKey")
//val encKey: String,
//@JsonProperty("encScheme")
//val encScheme: String = "RSAOAEPWithSHA256AESGCM",
//@JsonProperty("sigAlg")
//val sigAlg: String = "SHA256withECDSA"
//)


