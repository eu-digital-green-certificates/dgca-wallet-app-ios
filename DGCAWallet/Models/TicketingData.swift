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
//  TicketingData.swift
//  DGCAWallet
//  
//  Created by Illia Vlasov on 20.09.2021.
//  
        

import Foundation

struct TicketingQR : Codable {
  var protocolName    : String
  var protocolVersion : String
  var serviceIdentity : String
  var token           : String
  var consent         : String
  var subject         : String
  var serviceProvider : String
}
