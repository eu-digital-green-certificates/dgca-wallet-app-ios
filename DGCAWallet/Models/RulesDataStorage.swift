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
//  File.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 22.06.2021.
//  
import Foundation
import SwiftDGC
import SwiftyJSON
import CertLogic

class RulesDataStorage: Codable {
  static var sharedInstance = RulesDataStorage()
  static let storage = SecureStorage<RulesDataStorage>(fileName: "rules_secure")

  var rules = [CertLogic.Rule]()
  var lastFetchRaw: Date?
  var lastFetch: Date {
    get {
      lastFetchRaw ?? .init(timeIntervalSince1970: 0)
    }
    set(value) {
      lastFetchRaw = value
    }
  }

  func add(rule: CertLogic.Rule) {
    let list = rules
    if list.contains(where: { $0.identifier == rule.identifier && $0.version == rule.version }) {
      return
    }
    rules.append(rule)
  }

  func save(completion: ((Bool) -> Void)? = nil) {
    Self.storage.save(self, completion: completion)
  }

  func deleteRuleWithHash(hash: String) {
    self.rules = self.rules.filter { $0.hash != hash }
  }
    
  func isRuleExistWithHash(hash: String) -> Bool {
    let list = rules
    return list.contains(where: { $0.hash == hash })
  }
    
  static func initialize(completion: @escaping () -> Void) {
    storage.loadOverride(fallback: RulesDataStorage.sharedInstance) { success in
      guard let result = success else { return }
      let format = l10n("log.rules")
      print(String.localizedStringWithFormat(format, result.rules.count))
      RulesDataStorage.sharedInstance = result
      completion()
    }
  }
}
