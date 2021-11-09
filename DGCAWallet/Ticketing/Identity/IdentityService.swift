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
//  IdentityService.swift
//  DGCAWallet
//  
//  Created by Illia Vlasov on 19.10.2021.
//  
import Foundation
import Alamofire
import SwiftDGC

import Foundation
class IdentityService {
  static func requestListOfServices(ticketingInfo : CheckInQR, completion : @escaping ((ServerListResponse?) -> Void)) {
    let decoder = JSONDecoder()
    
    UserDefaults.standard.set(ticketingInfo.token, forKey: "TicketingToken")
    
    let headers = HTTPHeaders([HTTPHeader(name: "X-Version", value: "1.0.0"),HTTPHeader(name: "content-type", value: "application/json")])
    
    let url = URL(string: ticketingInfo.serviceIdentity)!
    var request = URLRequest(url: url)
    request.headers = headers
    
    let session = URLSession.shared.dataTask(with: request, completionHandler: { data,response,error in
      if let responseData = data {
        
        let responseModel = try! decoder.decode(ServerListResponse.self, from: responseData)
        
        completion(responseModel)
      } else {
        completion(nil)
      }
      
    })
    session.resume()
  }
  
  static func getServiceInfo(url : URL, completion: @escaping (ServerListResponse?) -> Void) {
    let decoder = JSONDecoder()
    let headers = HTTPHeaders([HTTPHeader(name: "X-Version", value: "1.0.0"),HTTPHeader(name: "content-type", value: "application/json")])
    
    var request = URLRequest(url: url)
    request.headers = headers
    
    let session = URLSession.shared.dataTask(with: request, completionHandler: { data,response,error in
      guard let data = data else {
        completion(nil)
        return
      }
      let responseModel = try! decoder.decode(ServerListResponse.self, from: data)
      completion(responseModel)
    })
    session.resume()
  }
}
