//
/*-
 * ---license-start
 * eu-digital-green-certificates / dgca-verifier-app-ios
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
//  TicketingConnection.swift
//  
//
//  Created by Denis Melenevsky on 22.12.2021.
//

import Foundation
import SwiftDGC
import SwiftyJSON
import JWTDecode

typealias TicketingCompletion = (AccessTokenResponse?, Error?) -> Void

class TicketingConnection {    
    static func loadAccessToken(_ url : URL, servicePath : String, publicKey: String, completion: @escaping TicketingCompletion) {
      let json: [String: Any] = ["service": servicePath, "pubKey": publicKey]
      
      guard let jsonData = try? JSONSerialization.data(withJSONObject: json,options: .prettyPrinted),
        let tokenData = KeyChain.load(key: TicketingKeys.keyTicketingToken)  else {
        completion(nil, GatewayError.tokenError)
        return
      }
      let token = String(decoding: tokenData, as: UTF8.self)

      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.httpBody = jsonData
      request.addValue( "1.0.0", forHTTPHeaderField: "X-Version")
      request.addValue( "application/json", forHTTPHeaderField: "content-type")
      request.addValue( "Bearer " + token, forHTTPHeaderField: "Authorization")

      let session = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
        guard error == nil else {
          completion(nil, GatewayError.connection(error: error!))
          return
        }
        guard let responseData = data, let tokenJWT = String(data: responseData, encoding: .utf8), responseData.count > 0 else {
          completion(nil, GatewayError.incorrectDataResponse)
          return
        }
        do {
          let decodedToken = try decode(jwt: tokenJWT)
          let jsonData = try JSONSerialization.data(withJSONObject: decodedToken.body)
          let accessTokenResponse = try JSONDecoder().decode(AccessTokenResponse.self, from: jsonData)
          
          if let tokenData = tokenJWT.data(using: .utf8) {
            KeyChain.save(key: TicketingKeys.keyAccessToken, data: tokenData)
          }
          if let httpResponse = response as? HTTPURLResponse,
             let xnonceData = (httpResponse.allHeaderFields["x-nonce"] as? String)?.data(using: .utf8) {
            KeyChain.save(key: TicketingKeys.keyXnonce, data: xnonceData)
          }
          completion(accessTokenResponse, nil)

        } catch {
          completion(nil, GatewayError.encodingError)
          DGCLogger.logError(error)
        }
      })
      session.resume()
    }
    
    static func validateTicketing(url : URL, parameters : [String: String]?, completion : @escaping TicketingCompletion) {
      guard let parametersData = try? JSONEncoder().encode(parameters) else {
        completion(nil, GatewayError.encodingError)
        return
      }
      guard let tokenData = KeyChain.load(key: TicketingKeys.keyAccessToken) else {
        completion(nil, GatewayError.tokenError)
        return
      }
      let token = String(decoding: tokenData, as: UTF8.self)
      
      var request = URLRequest(url: url)
      request.method = .post
      request.httpBody = parametersData
      
      request.addValue( "1.0.0", forHTTPHeaderField: "X-Version")
      request.addValue( "application/json", forHTTPHeaderField: "content-type")
      request.addValue( "Bearer " + token, forHTTPHeaderField: "Authorization")

      let session = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
        guard error == nil else {
          completion(nil,GatewayError.connection(error: error!))
          return
        }
        guard let responseData = data, let tokenJWT = String(data: responseData, encoding: .utf8) else {
          completion(nil, GatewayError.incorrectDataResponse)
          return
        }
        do {
          let decodedToken = try decode(jwt: tokenJWT)
          let jsonData = try JSONSerialization.data(withJSONObject: decodedToken.body)
          let decoder = JSONDecoder()
          let accessTokenResponse = try decoder.decode(AccessTokenResponse.self, from: jsonData)
          completion(accessTokenResponse, nil)
          
        } catch {
          completion(nil, GatewayError.parsingError)
          DGCLogger.logError(error)
        }
      })
      session.resume()
    }

}
