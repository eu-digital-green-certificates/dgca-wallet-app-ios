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

typealias CompletionHandler = () -> Void

extension DataCenter {

  static let countryDataManager: CountryDataManager = CountryDataManager()
  static let rulesDataManager: RulesDataManager = RulesDataManager()
  static let valueSetsDataManager: ValueSetsDataManager = ValueSetsDataManager()
  static let imageDataManager: ImageDataManager = ImageDataManager()
  static let pdfDataManager: PdfDataManager = PdfDataManager()
  
  // MARK: - public variables
  
  static var images: [SavedImage] {
    return imageDataManager.localData.images
  }
  
  static var pdfs: [SavedPDF] {
    return pdfDataManager.localData.pdfs
  }
  
  static var countryCodes: [CountryModel] {
    return countryDataManager.localData.countryCodes
  }
  
  static var rules: [CertLogic.Rule] {
    get {
      return rulesDataManager.localData.rules
    }
    set {
      rulesDataManager.localData.rules = newValue
    }
  }
  
  static var valueSets: [CertLogic.ValueSet] {
    get {
      return valueSetsDataManager.localData.valueSets
    }
    set {
      valueSetsDataManager.localData.valueSets = newValue
    }
  }
  
  // MARK: - Data Add methods
  static func addCountries(_ list: [CountryModel], completion: @escaping DataCompletionHandler) {
    countryDataManager.localData.countryCodes.removeAll()
    list.forEach { country in
      countryDataManager.add(country: country)
    }
    countryDataManager.save(completion: completion)
  }
  
  static func addRules(_ list: [CertLogic.Rule], completion: @escaping DataCompletionHandler) {
    rules.forEach { rulesDataManager.add(rule: $0) }
    rulesDataManager.save(completion: completion)
  }
  
  static func addValueSets(_ list: [CertLogic.ValueSet], completion: @escaping DataCompletionHandler) {
    list.forEach { valueSetsDataManager.add(valueSet: $0) }
    valueSetsDataManager.save(completion: completion)
  }
  
  // MARK: - Data initialize methods
  static func initializeLocalData(completion: @escaping DataCompletionHandler) {
    localDataManager.loadLocallyStoredData(completion: completion)
  }
  
  static func initializeAllStorageData(completion: @escaping DataCompletionHandler) {
    let group = DispatchGroup()
    
    group.enter()
    localDataManager.loadLocallyStoredData { result in
     // guard case let .success(value) = result, value == true else { completion(result); return }

      group.enter()
      rulesDataManager.loadLocallyStoredData { result in
        //guard case let .success(value) = result, value == true else { completion(result); return }

        CertLogicManager.shared.setRules(ruleList: rules)
        group.leave()
      }
      
      group.enter()
      valueSetsDataManager.loadLocallyStoredData { result in
        //guard case let .success(value) = result, value == true else { completion(result); return }
        group.leave()
      }
      
      group.enter()
      countryDataManager.loadLocallyStoredData { result in
        //guard case let .success(value) = result, value == true else { completion(result); return }
        group.leave()
      }
      
      group.enter()
      imageDataManager.loadLocallyStoredData { result in
        //guard case let .success(value) = result, value == true else { completion(result); return }
        group.leave()
      }
      
      group.enter()
      pdfDataManager.loadLocallyStoredData { result in
        //guard case let .success(value) = result, value == true else { completion(result); return }
        group.leave()
      }
      group.leave()
    }
    
    group.notify(queue: .main) {
      completion(.success(true))
    }
  }

  static func reloadStorageData(completion: @escaping DataCompletionHandler) {
    let group = DispatchGroup()
    
    group.enter()
    localDataManager.loadLocallyStoredData { result in
      //guard case let .success(value) = result, value == true else { completion(result); return }

      group.enter()
      rulesDataManager.loadLocallyStoredData { result in
        //guard case let .success(value) = result, value == true else { completion(result); return }
        CertLogicManager.shared.setRules(ruleList: rules)
        group.leave()
      }
      
      group.enter()
      valueSetsDataManager.loadLocallyStoredData { result in
        //guard case let .success(value) = result, value == true else { completion(result); return }
        group.leave()
      }
      
      group.enter()
      countryDataManager.loadLocallyStoredData { result in
        //guard case let .success(value) = result, value == true else { completion(result); return }
        group.leave()
      }
      
      group.enter()
      GatewayConnection.loadCountryList { list, error in
        guard error == nil else { completion(.failure(error!)); return }

        group.leave()
      }
      
      group.enter()
      imageDataManager.loadLocallyStoredData { result in
        //guard case let .success(value) = result, value == true else { completion(result); return }
        group.leave()
      }
      
      group.enter()
      pdfDataManager.loadLocallyStoredData { result in
        //guard case let .success(value) = result, value == true else { completion(result); return }
        group.leave()
      }

      group.enter()
      GatewayConnection.loadValueSetsFromServer { list, error in
        guard error == nil else { completion(.failure(error!)); return }

        group.leave()
      }
      
      group.enter()
      GatewayConnection.loadRulesFromServer { listRules, error in
        guard error == nil else { completion(.failure(error!)); return }

        CertLogicManager.shared.setRules(ruleList: listRules ?? [])
        group.leave()
      }

      group.leave()
    }
        
    group.notify(queue: .main) {
      localDataManager.localData.lastFetch = Date()
      localDataManager.localData.lastLaunchedAppVersion = Self.appVersion
      localDataManager.save(completion: completion)
    }
  }
}
