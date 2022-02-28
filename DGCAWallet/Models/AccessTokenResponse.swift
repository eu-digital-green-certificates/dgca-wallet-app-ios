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
//  AccessTokenResponse.swift
//  DGCAWallet
//  
//  Created by Illia Vlasov on 22.09.2021.
//  
        

import Foundation

struct AccessTokenResponse : Codable {
  let jti           : String?
  let lss           : String?
  let iat           : Int?
  let sub           : String?
  let aud           : String?
  let exp           : Int?
  let t             : Int?
  let v             : String?
  let confirmation  : String?
  let vc            : ValidationCertificate?
  let result        : String?
  let results       : [LimitationInfo]?
}

struct LimitationInfo : Codable {
  let identifier  : String
  let result      : String
  let type        : String
  let details     : String
}

struct ValidationCertificate : Codable {
  let lang            : String
  let fnt             : String
  let gnt             : String
  let dob             : String
  let coa             : String
  let cod             : String
  let roa             : String
  let rod             : String
  let type            : [String]
  let category        : [String]
  let validationClock : String
  let validFrom       : String
  let validTo         : String
}
