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
//  LocalDataManager.swift
//  DGCAVerifier
//  
//  Created by Yannick Spreen on 4/25/21.
//  

import Foundation
import SwiftDGC
import SwiftyJSON

class LocalDataManager {
    private enum Constants {
      static let pubKeysStorageFilename = "secure"
      static let bundleVersion = "CFBundleShortVersionString"
      static let unknown = "?.?.?"
      static let versions = "versions"
      static let defaultVer = "default"
    }

  lazy var storage = SecureStorage<LocalData>(fileName: Constants.pubKeysStorageFilename)
  lazy var localData: LocalData = LocalData()

    func add(_ cert: HCert, with tan: String?, completion: ((Bool) -> Void)? = nil) {
      localData.certStrings.append(DatedCertString(date: Date(), certString: cert.fullPayloadString, storedTAN: tan))
      storage.save(localData, completion: completion)
    }

    func remove(withDate date: Date, completion: ((Bool) -> Void)? = nil) {
      if let ind = localData.certStrings.firstIndex(where: { $0.date == date }) {
        localData.certStrings.remove(at: ind)
        storage.save(localData, completion: completion)
      }
    }

  func merge(other: JSON) {
    localData.config.merge(other: other)
  }
  
  func save(completion: ((Bool) -> Void)? = nil) {
    storage.save(localData, completion: completion)
  }

  func initialize(completion: @escaping () -> Void) {
    storage.loadOverride(fallback: localData) { [unowned self] success in
      guard let result = success else {  return }
      
      let format = l10n("log.certs-loaded")
      print(String.localizedStringWithFormat(format, result.certStrings.count))
      if result.lastLaunchedAppVersion != DataCenter.appVersion {
        result.config = self.localData.config
      }
      self.localData = result
      completion()
    }
  }
  
  var versionedConfig: JSON {
    if localData.config["versions"][DataCenter.appVersion].exists() {
      return localData.config["versions"][DataCenter.appVersion]
    } else {
      return localData.config["versions"]["default"]
    }
  }
}
