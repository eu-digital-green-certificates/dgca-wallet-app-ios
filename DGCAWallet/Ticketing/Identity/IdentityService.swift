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
import SwiftDGC

enum IdentityError: Error {
  case wrongData
  case connection(error: Error)
  case parsingError
}

typealias IdentityCompletion = (ServerListResponse?, Error?) -> Void

class IdentityService {
  static func requestListOfServices(ticketingInfo : CheckInQR, completion : @escaping IdentityCompletion) {
    UserDefaults.standard.set(ticketingInfo.token, forKey: "TicketingToken")
    
    let url = URL(string: ticketingInfo.serviceIdentity)!
    var request = URLRequest(url: url)
    request.addValue( "1.0.0", forHTTPHeaderField: "X-Version")
    request.addValue( "application/json", forHTTPHeaderField: "content-type")
    
    let session = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
      guard error == nil else {
        completion(nil, IdentityError.connection(error: error!))
        return
      }
      
      guard let responseData = data else {
          completion(nil, IdentityError.wrongData)
          return
      }
      
      do {
        let responseModel = try JSONDecoder().decode(ServerListResponse.self, from: responseData)
        completion(responseModel, nil)
      } catch {
        completion(nil, IdentityError.parsingError)
      }
    })
    session.resume()
  }
  
  static func getServiceInfo(url : URL, completion: @escaping IdentityCompletion) {
    var request = URLRequest(url: url)
    request.addValue( "1.0.0", forHTTPHeaderField: "X-Version")
    request.addValue( "application/json", forHTTPHeaderField: "content-type")

    let session = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
      guard error == nil else {
        completion(nil, IdentityError.connection(error: error!))
        return
      }

      guard let data = data else {
        completion(nil, IdentityError.wrongData)
        return
      }
      do {
        let responseModel = try JSONDecoder().decode(ServerListResponse.self, from: data)
        completion(responseModel, nil)
      } catch {
        completion(nil, IdentityError.parsingError)
      }
    })
    session.resume()
  }
}
