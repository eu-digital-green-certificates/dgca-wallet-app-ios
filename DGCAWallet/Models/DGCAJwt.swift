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
//  JWT.swift
//  DGCAWallet
//  
//  Created by Paul Ballmann on 01.03.22.
//  
        

import Foundation
import CryptoKit
import SwiftDGC

struct Header: Encodable {
	let alg = "ES256"
	let typ = "JWT"
}

struct Payload: Encodable {
	let sub: String
	let payload: [String]
	let exp: Double
}

class DGCAJwt {
	private static func makeJwtPayload(cert: HCert) -> Payload {
		/*
		let payload: [String] = [cert.uvciHash![0..<(cert.uvciHash!.count/2)].toHexString(),
								 cert.signatureHash![0..<(cert.signatureHash!.count/2)].toHexString(),
								 cert.countryCodeUvciHash![0..<(cert.countryCodeUvciHash!.count/2)].toHexString()]
		 */
		let payload: [String] = [cert.uvciHash!.dropLast(16).toHexString(),
								 cert.signatureHash!.dropLast(16).toHexString(),
								 cert.countryCodeUvciHash!.dropLast(16).toHexString()]
		return Payload(sub: cert.uvciHash!.toHexString(), payload: payload, exp: cert.exp.timeIntervalSince1970)
	}
	// payload: Payload, with keyPair: SecKey
	public static func makeJwtAndSign(fromCerts certs: [HCert], completion: @escaping (Bool, [String]?, Error?) -> Void) {
		var tokens: [String] = []
		for cert in certs {
			do {
				let payload = DGCAJwt.makeJwtPayload(cert: cert)
				let headerDataBase64 = try JSONEncoder().encode(Header()).urlSafeBase64EncodedString()
				let payloadBase64 = try JSONEncoder().encode(payload).urlSafeBase64EncodedString()
				let toSign = Data((headerDataBase64 + "." + payloadBase64).utf8)
				Enclave.sign(data: toSign, with: cert.keyPair, using: .ecdsaSignatureMessageX962SHA256) { sign, err in
					guard err == nil else {
						completion(false, nil, GatewayError.local(description: err!))
						return
					}
					guard let sign = sign else {
						completion(false, nil, GatewayError.local(description: err!))
						return
					}
					let signatureBase64 = sign.urlSafeBase64EncodedString()
					let token = [headerDataBase64, payloadBase64, signatureBase64].joined(separator: ".")
					// completion(true, token, nil)
					tokens.append(token)
					if tokens.count == certs.count {
						completion(true, tokens, nil)
					}
				}
			} catch {
				print(error)
				completion(false, nil, error)
				return
			}
		}
	}
}
