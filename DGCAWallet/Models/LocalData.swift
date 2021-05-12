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
//  LocalData.swift
//  DGCAWallet
//  
//  Created by Yannick Spreen on 4/25/21.
//

import Foundation
import SwiftDGC
import SwiftyJSON

struct DatedCertString: Codable {
  var date: Date
  var certString: String
  var storedTAN: String?
  var cert: HCert? {
    HCert(from: certString)
  }
}

struct LocalData: Codable {
  static let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "?.?.?"
  static var sharedInstance = LocalData()

  var certStrings = [DatedCertString]()
  var config = Config.load()

  public func save() {
    Self.storage.save(self)
  }

  public static func add(_ cert: HCert, with tan: String?) {
    sharedInstance.certStrings.append(.init(date: Date(), certString: cert.payloadString, storedTAN: tan))
    sharedInstance.save()
  }

  static let storage = SecureStorage<LocalData>()

  static func initialize(completion: @escaping () -> Void) {
    storage.loadOverride(fallback: LocalData.sharedInstance) { success in
      guard let result = success else {
        return
      }
      let format = l10n("log.certs-loaded")
      print(String.localizedStringWithFormat(format, result.certStrings.count))
      LocalData.sharedInstance = result
      completion()
    }
  }

  var versionedConfig: JSON {
    if config["versions"][Self.appVersion].exists() {
      return config["versions"][Self.appVersion]
    }
    return config["versions"]["default"]
  }
}
