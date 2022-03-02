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
//  DataStuctures.swift
//  DGCAVerifier
//  
//  Created by Igor Khomiak on 11/3/21.
//  


import Foundation
import SwiftDGC
import CertLogic

class DatedCertString: Codable {
	var isSelected: Bool = false
	let date: Date
	let certString: String
	let storedTAN: String?
	var cert: HCert? {
		return try? HCert(from: certString)
	}
	
	init(date: Date, certString: String, storedTAN: String?, isRevoked: Bool?) {
		self.date = date
		if isRevoked != nil && isRevoked == true {
			self.certString = "x" + certString
		} else {
			self.certString = certString
		}
		self.storedTAN = storedTAN
	}
}

class LocalData: Codable {
	var encodedPublicKeys = [String: [String]]()
	var certStrings = [DatedCertString]()
	
	var countryCodes = [CountryModel]()
	var valueSets = [ValueSet]()
	var rules = [Rule]()
	
	var resumeToken: String?
	var lastFetchRaw: Date?
	var lastFetch: Date {
		get {
			lastFetchRaw ?? Date.distantPast
		}
		set {
			lastFetchRaw = newValue
		}
	}
	var config = Config.load()
	var lastLaunchedAppVersion = "0.0"
}

class ImageDataStorage: Codable {
	var images = [SavedImage]()
}

class PdfDataStorage: Codable {
	var pdfs = [SavedPDF]()
}
