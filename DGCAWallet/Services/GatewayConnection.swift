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

struct GatewayConnection {
  static let serverURI = "https://dgca-issuance-web.cfapps.eu10.hana.ondemand.com/"
  static let claimEndpoint = "dgci/wallet/claim"

  public static func claim(cert: HCert, with tan: String?, completion: ((Bool) -> Void)?) {
    guard var tan = tan, !tan.isEmpty else {
      completion?(false)
      return
    }
    // Replace dashes, spaces, etc. and turn into uppercase.
    let set = CharacterSet(charactersIn: "0123456789").union(.capitalizedLetters)
    tan = tan.uppercased().components(separatedBy: set.inverted).joined()

    let tanHash = SHA256.stringDigest(input: Data(tan.encode()))
    let certHash = cert.certHash
    let pubKey = (X509.derPubKey(for: cert.keyPair) ?? Data()).base64EncodedString()

    let toBeSigned = tanHash + certHash + pubKey
    let toBeSignedData = Data(toBeSigned.encode())
    Enclave.sign(data: toBeSignedData, with: cert.keyPair) { sign, err in
      guard let sign = sign, err == nil else {
        return
      }

      let keyParam: [String: Any] = [
        "type": "EC256",
        "value": "pubkey",
      ]
      let param: [String: Any] = [
        "DGCI": cert.uvci,
        "TANHash": tanHash,
        "certhash": certHash,
        "publicKey": keyParam,
        "signature": sign.base64EncodedData(),
      ]
      AF.request(serverURI + claimEndpoint, method: .get, parameters: param, encoding: JSONEncoding.default, headers: nil, interceptor: nil, requestModifier: nil).response {
        guard
          case .success(_) = $0.result,
          let status = $0.response?.statusCode,
          status == 204
        else {
          completion?(false)
          return
        }
        completion?(true)
      }
    }
  }
}
