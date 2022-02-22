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

class DataCenter {
    static let shared = DataCenter()
    static var appVersion: String {
      let versionValue = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "?.?.?"
      let buildNumValue = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "?.?.?"
      return "\(versionValue)(\(buildNumValue))"
    }

    static let localDataManager: LocalDataManager = LocalDataManager()
    static let imageDataManager: ImageDataManager = ImageDataManager()
    static let pdfDataManager: PdfDataManager = PdfDataManager()
    static let revocationWorker: RevocationWorker = RevocationWorker()

    static var downloadedDataHasExpired: Bool {
        return lastFetch.timeIntervalSinceNow < -SharedConstants.expiredDataInterval
    }
   
    static var appWasRunWithOlderVersion: Bool {
        return localDataManager.localData.lastLaunchedAppVersion != appVersion
    }

    // MARK: - public variables
  
    static var lastFetch: Date {
        get {
            return localDataManager.localData.lastFetch
        }
        set {
            localDataManager.localData.lastFetch = newValue
        }
    }

    static var lastLaunchedAppVersion: String {
      return DataCenter.localDataManager.localData.lastLaunchedAppVersion
    }

    static var certStrings: [DatedCertString] {
        get {
          return localDataManager.localData.certStrings
        }
        set {
          localDataManager.localData.certStrings = newValue
        }
    }
  
    static var resumeToken: String? {
        get {
            return localDataManager.localData.resumeToken
        }
        set {
            localDataManager.localData.resumeToken = newValue
        }
    }

    static var images: [SavedImage] {
        get {
            return imageDataManager.localData.images
        }
        set {
            imageDataManager.localData.images = newValue
        }
    }
    
    static var pdfs: [SavedPDF] {
        get {
            return pdfDataManager.localData.pdfs
        }
        set {
            pdfDataManager.localData.pdfs = newValue
        }
    }

    static var countryCodes: [CountryModel] {
        get {
            return localDataManager.localData.countryCodes
        }
        set {
            localDataManager.localData.countryCodes = newValue
        }
    }

    static var rules: [Rule] {
        get {
          return localDataManager.localData.rules
        }
        set {
            localDataManager.localData.rules = newValue
        }
    }
    
    static var valueSets: [ValueSet] {
        get {
          return localDataManager.localData.valueSets
        }
        set {
            localDataManager.localData.valueSets = newValue
        }
    }
    
    static func saveLocalData() {
        localDataManager.save { rez in }
    }
    
    static func addValueSets(_ list: [ValueSet]) {
        list.forEach { localDataManager.add(valueSet: $0) }
    }

    static func addRules(_ list: [Rule]) {
        list.forEach { localDataManager.add(rule: $0) }
    }

    static func addCountries(_ list: [CountryModel]) {
        localDataManager.localData.countryCodes.removeAll()
        list.forEach { localDataManager.add(country: $0) }
    }

    // MARK: - Data initialize methods
    class func prepareLocalData(completion: @escaping DataCompletionHandler) {
        initializeAllStorageData { result in
            let shouldDownload = self.downloadedDataHasExpired || self.appWasRunWithOlderVersion
            if !shouldDownload {
                completion(result)
            } else {
                reloadStorageData { result in
                    initializeAllStorageData { result in
                        completion(result)
                    }
                }
            }
        }
    }

    static func initializeAllStorageData(completion: @escaping DataCompletionHandler) {
        let group = DispatchGroup()
        
        group.enter()
        localDataManager.loadLocallyStoredData { result in
            CertLogicManager.shared.setRules(ruleList: rules)
                
            group.enter()
            imageDataManager.loadLocallyStoredData { result in
              group.leave()
            }
            
            group.enter()
            pdfDataManager.loadLocallyStoredData { result in
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
        
        let center = NotificationCenter.default
        center.post(name: Notification.Name("StartLoadingNotificationName"), object: nil, userInfo: nil )
        
        group.enter()
        localDataManager.loadLocallyStoredData { result in
            CertLogicManager.shared.setRules(ruleList: rules)
            
            group.enter()
            imageDataManager.loadLocallyStoredData { result in
              group.leave()
            }
            
            group.enter()
            pdfDataManager.loadLocallyStoredData { result in
              group.leave()
            }
            
            group.enter()
            GatewayConnection.loadCountryList { list, error in
                group.leave()
            }

            group.enter()
            GatewayConnection.loadValueSetsFromServer { list, error in
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
        
        group.enter()
        revocationWorker.processReloadRevocations { error in
            if let err = error {
                if case let .failedValidation(status: status) = err, status == 404 {
                    revocationWorker.processReloadRevocations { err in
                        print("Backend error!!")
                    }
                }
            }
            
            group.leave()
        }
        
        group.notify(queue: .main) {
            localDataManager.localData.lastFetch = Date()
            center.post(name: Notification.Name("StopLoadingNotificationName"), object: nil, userInfo: nil )
            localDataManager.localData.lastLaunchedAppVersion = Self.appVersion
            localDataManager.save(completion: completion)
        }
    }
}
