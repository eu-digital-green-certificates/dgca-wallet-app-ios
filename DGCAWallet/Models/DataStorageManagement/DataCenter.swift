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
//  DataCenter.swift
//  DGCAVerifier
//  
//  Created by Igor Khomiak on 03.11.2021.
//  
        
import UIKit
import SwiftDGC
import CertLogic

class DataCenter {
  static let shared = DataCenter()
  static let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "?.?.?"

  static let localDataManager: LocalDataManager = LocalDataManager()
  static let countryDataManager: CountryDataManager = CountryDataManager()
  static let rulesDataManager: RulesDataManager = RulesDataManager()
  static let valueSetsDataManager: ValueSetsDataManager = ValueSetsDataManager()
  static let imageDataManager: ImageDataManager = ImageDataManager()
  static let pdfDataManager: PdfDataManager = PdfDataManager()
  
  static var lastFetch: Date {
    get {
      let fetchDate = localDataManager.localData.lastFetch
      return fetchDate
    }
    set {
      localDataManager.localData.lastFetch = newValue
     }
  }
  
  static var lastLaunchedAppVersion: String {
    get {
      return DataCenter.localDataManager.localData.lastLaunchedAppVersion
    }
    set {
      DataCenter.localDataManager.localData.lastLaunchedAppVersion = newValue
     }
  }
  
  static var certStrings: [DatedCertString] {
    get {
      return localDataManager.localData.certStrings
    }
    set {
      localDataManager.localData.certStrings = newValue
    }
  }

  static var images: [SavedImage] {
    get {
      return imageDataManager.imageData.images
    }
    set {
      imageDataManager.imageData.images = newValue
    }
  }
  
  static var pdfs: [SavedPDF] {
    get {
      return pdfDataManager.pdfData.pdfs
    }
    set {
      pdfDataManager.pdfData.pdfs = newValue
    }
  }

  static var countryCodes: [CountryModel] {
    get {
      return countryDataManager.countryData.countryCodes
    }
    set {
      countryDataManager.countryData.countryCodes = newValue
    }
  }
  
  static var rules: [CertLogic.Rule] {
    get {
      return rulesDataManager.rulesData.rules
    }
    set {
      rulesDataManager.rulesData.rules = newValue
    }
  }
  
  static var valueSets: [CertLogic.ValueSet] {
    get {
      return valueSetsDataManager.valueSetsData.valueSets
    }
    set {
      valueSetsDataManager.valueSetsData.valueSets = newValue
    }
  }

  static func saveLocalData() {
    localDataManager.save()
  }
  
  static func saveCountries() {
    countryDataManager.save()
  }
  
  static func saveSets() {
    valueSetsDataManager.save()
  }

  static func saveRules() {
    rulesDataManager.save()
  }
  
  static func saveImages() {
    imageDataManager.save()
  }
  
  static func savePDFs() {
    pdfDataManager.save()
  }

  static func initializeLocalData(completion: @escaping () -> Void) {
    localDataManager.initialize(completion: completion)
  }
  
  static func initializeAllStorageData(completion: @escaping () -> Void) {
    let group = DispatchGroup()
    
    group.enter()
    localDataManager.initialize {
      
      group.enter()
      rulesDataManager.initialize {
        CertLogicManager.shared.setRules(ruleList: rules)
        group.leave()
      }
      
      group.enter()
      valueSetsDataManager.initialize {
        group.leave()
      }
      
      group.enter()
      countryDataManager.initialize {
        group.leave()
      }
      
      group.enter()
      imageDataManager.initialize {
        group.leave()
      }
      
      group.enter()
      pdfDataManager.initialize {
        group.leave()
      }

      group.leave()
    }
    group.notify(queue: .main) {
      completion()
    }
  }

  static func reloadStorageData(completion: @escaping () -> Void) {
    let group = DispatchGroup()
    
    group.enter()
    localDataManager.initialize {
      
      group.enter()
      rulesDataManager.initialize {
        CertLogicManager.shared.setRules(ruleList: rules)
        group.leave()
      }
      
      group.enter()
      valueSetsDataManager.initialize {
        group.leave()
      }
      
      group.enter()
      countryDataManager.initialize {
        group.leave()
      }
      
//      group.enter()
//      GatewayConnection.updateLocalDataStorage {
//        group.leave()
//      }

      group.enter()
      GatewayConnection.loadCountryList { _ in
        saveCountries()
        group.leave()
      }
      
      group.enter()
      GatewayConnection.loadValueSetsFromServer { _ in
        saveSets()
        group.leave()
      }
      
      group.enter()
      GatewayConnection.loadRulesFromServer { _ in
        CertLogicManager.shared.setRules(ruleList: rules)
        saveRules()
        group.leave()
      }

      group.leave()
    }
    group.notify(queue: .main) {
      lastFetch = Date()
      saveLocalData()
      completion()
    }
  }
}
