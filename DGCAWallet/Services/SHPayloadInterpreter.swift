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
//  SHPayloadInterpreter.swift
//  DGCAWallet
//  
//  Created by Paul Ballmann on 08.04.22.
//  
        

import Foundation
import SwiftPath

public class SHInterpreter {
	
	private var jsonPaths: [String:String] = [
		"givenName": "$.vc..name..given.*",
		"familyName": "$.vc..name..family",
		"birthDate": "$.vc..birthDate",
		"type": "$.vc.type.*",
		"doseDate": "$.vc..occurrenceDateTime",
		"issuer": "$.vc.*..display"
	]
	
	private var dataMap: [String:String] = [:]
	
	public init(payload: String) {
		jsonPaths.forEach { key, value in
			if let jsonPath = SwiftPath(value),
			   let mapped = try? jsonPath.evaluate(with: payload) {
				
			}
		}
	}
	
	
}
