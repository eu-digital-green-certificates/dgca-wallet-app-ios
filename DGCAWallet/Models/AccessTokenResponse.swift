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
  var jti           : String?
  var lss           : String?
  var iat           : Int?
  var sub           : String?
  var aud           : String?
  var exp           : Int?
  var t             : Int?
  var v             : String?
  var confirmation  : String?
  var vc            : ValidationCertificate?
  var result        : String?
  var results       : [LimitationInfo]?
}

struct LimitationInfo : Codable {
  var identifier  : String?
  var result      : String?
  var type        : String?
  var details     : String?
}

struct ValidationCertificate : Codable {
  var lang            : String?
  var fnt             : String?
  var gnt             : String?
  var dob             : String?
  var coa             : String?
  var cod             : String?
  var roa             : String?
  var rod             : String?
  var type            : [String]?
  var category        : [String]?
  var validationClock : String?
  var validFrom       : String?
  var validTo         : String?
}

