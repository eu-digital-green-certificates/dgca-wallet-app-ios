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
    guard let tan = tan, !tan.isEmpty else {
      completion?(false)
      return
    }
    let param: [String: Any] = [
      "dgci": cert.uvci,
      "tanHash": SHA256.stringDigest(input: Data(tan.encode())),
      "certHash": cert.certHash,
      "pubKey": "TODO: DER encoded cert.keyPair pubkey",
      "signature": "TODO: signature",
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
