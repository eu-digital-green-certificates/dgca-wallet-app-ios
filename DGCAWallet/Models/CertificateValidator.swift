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
//  CertificateValidator..swift
//
//
//  Created by Igor Khomiak on 15.10.2021.
//

import Foundation
import SwiftDGC
import CertLogic

public typealias ValidityCompletion = (ValidityState) -> Void

public class CertificateValidator {
    
    public let certificate: HCert

    init(with cert: HCert) {
      self.certificate = cert
    }

  func validate(completion: ValidityCompletion) {
      let failures = findValidityFailures()
      
      let technicalValidity: HCertValidity = failures.isEmpty ? .valid : .invalid
      let issuerValidity = validateCertLogicForIssuer()
      let destinationValidity = validateCertLogicForDestination()
      let travalerValidity = validateCertLogicForTraveller()
      let (infoRulesSection, allRulesValidity): (InfoSection?, HCertValidity)
      if technicalValidity == .valid {
          (infoRulesSection, allRulesValidity) = validateCertLogicForAllRules()
      } else {
          (infoRulesSection, allRulesValidity) = (nil, .invalid)
      }

      let validityState = ValidityState(
        technicalValidity: technicalValidity,
        issuerValidity: issuerValidity,
        destinationValidity: destinationValidity,
        travalerValidity: travalerValidity,
        allRulesValidity: allRulesValidity,
        revocationValidity: .valid,
        validityFailures: failures,
        infoRulesSection: infoRulesSection)

    completion(validityState)
  }
  
  private func findValidityFailures() -> [String] {
    var failures = [String]()
    if !certificate.cryptographicallyValid {
      failures.append("No entries in the certificate.".localized)
    }
    if certificate.exp < HCert.clock {
      failures.append("Certificate past expiration date.".localized)
    }
    if certificate.iat > HCert.clock {
      failures.append("Certificate issuance date is in the future.".localized)
    }
    if certificate.statement == nil {
      failures.append("No entries in the certificate.".localized)
      return failures
    }
    failures.append(contentsOf: certificate.statement.validityFailures)
    return failures
  }

  // MARK: - private validation methods
  private func validateCertLogicForAllRules() -> (InfoSection?, HCertValidity) {
      var validity: HCertValidity = .valid
      let certType = certificationType(for: certificate.certificateType)
      var infoSection: InfoSection?
    
      if let countryCode = certificate.ruleCountryCode {
        let valueSets = DataCenter.localDataManager.getValueSetsForExternalParameters()
        let filterParameter = FilterParameter(validationClock: Date(),
            countryCode: countryCode,
            certificationType: certType)
        let externalParameters = ExternalParameter(validationClock: Date(),
             valueSets: valueSets,
             exp: certificate.exp,
             iat: certificate.iat,
             issuerCountryCode: certificate.issCode,
             kid: certificate.kidStr)
        let result = CertLogicManager.shared.validate(filter: filterParameter,
            external: externalParameters, payload: certificate.body.description)
        let failsAndOpen = result.filter { $0.result != .passed }
        
        if failsAndOpen.count > 0 {
          validity = .ruleInvalid
          infoSection = InfoSection(header: "Possible limitation", content: "Country rules validation failed")
          var listOfRulesSection: [InfoSection] = []
          result.sorted(by: { $0.result.rawValue < $1.result.rawValue }).forEach { validationResult in
            if let error = validationResult.validationErrors?.first {
              switch validationResult.result {
              case .fail:
                listOfRulesSection.append(InfoSection(header: "CirtLogic Engine error",
                    content: error.localizedDescription,
                    countryName: certificate.ruleCountryCode,
                    ruleValidationResult: .failed))
              case .open:
                listOfRulesSection.append(InfoSection(header: "CirtLogic Engine error",
                    content: error.localizedDescription,
                    countryName: certificate.ruleCountryCode,
                    ruleValidationResult: .open))
              case .passed:
                listOfRulesSection.append(InfoSection(header: "CirtLogic Engine error",
                    content: error.localizedDescription,
                    countryName: certificate.ruleCountryCode,
                    ruleValidationResult: .passed))
              }
              
            } else {
              let preferredLanguage = Locale.preferredLanguages[0] as String
              let arr = preferredLanguage.components(separatedBy: "-")
              let deviceLanguage = (arr.first ?? "EN")
              var errorString = ""
              if let error = validationResult.rule?.getLocalizedErrorString(locale: deviceLanguage) {
                errorString = error
              }
              var detailsError = ""
              if let rule = validationResult.rule {
                let dict = CertLogicManager.shared.getRuleDetailsError(rule: rule, filter: filterParameter)
                dict.keys.forEach({ detailsError += $0 + ": " + (dict[$0] ?? "") + " " })
              }
              switch validationResult.result {
              case .fail:
                listOfRulesSection.append(InfoSection(header: errorString,
                    content: detailsError,
                    countryName: certificate.ruleCountryCode,
                    ruleValidationResult: .failed))
              case .open:
                listOfRulesSection.append(InfoSection(header: errorString,
                    content: detailsError,
                    countryName: certificate.ruleCountryCode,
                    ruleValidationResult: .open))
              case .passed:
                listOfRulesSection.append(InfoSection(header: errorString,
                    content: detailsError,
                    countryName: certificate.ruleCountryCode,
                    ruleValidationResult: .passed))
              }
            }
          }
          infoSection?.sectionItems = listOfRulesSection
        }
      }
      return (infoSection, validity)
    }
        
    private func validateCertLogicForIssuer() -> HCertValidity {
      let certType = certificationType(for: certificate.certificateType)
      if let countryCode = certificate.ruleCountryCode {
        let valueSets = DataCenter.localDataManager.getValueSetsForExternalParameters()
        let filterParameter = FilterParameter(validationClock: Date(),
            countryCode: countryCode,
            certificationType: certType)
        let externalParameters = ExternalParameter(validationClock: Date(),
           valueSets: valueSets,
           exp: certificate.exp,
           iat: certificate.iat,
           issuerCountryCode: certificate.issCode,
           kid: certificate.kidStr)
        let result = CertLogicManager.shared.validateIssuer(filter: filterParameter,
            external: externalParameters, payload: certificate.body.description)
        let fails = result.filter { $0.result == .fail }
        if !fails.isEmpty {
          return .invalid
        }
        let open = result.filter { $0.result == .open }
        if !open.isEmpty {
          return .ruleInvalid
        }
      }
      return .valid
    }

    private func validateCertLogicForDestination() -> HCertValidity {
      let certType = certificationType(for: certificate.certificateType)
      if let countryCode = certificate.ruleCountryCode {
        let valueSets = DataCenter.localDataManager.getValueSetsForExternalParameters()
        let filterParameter = FilterParameter(validationClock: Date(),
          countryCode: countryCode,
          certificationType: certType)
        let externalParameters = ExternalParameter(validationClock: Date(),
          valueSets: valueSets,
          exp: certificate.exp,
          iat: certificate.iat,
          issuerCountryCode: certificate.issCode,
          kid: certificate.kidStr)
        let result = CertLogicManager.shared.validateDestination(filter: filterParameter,
            external: externalParameters, payload: certificate.body.description)
        let fails = result.filter { $0.result == .fail }
        if !fails.isEmpty {
          return .invalid
        }
        let open = result.filter { $0.result == .open }
        if !open.isEmpty {
          return .ruleInvalid
        }
      }
      return .valid
    }
    
    private func validateCertLogicForTraveller() -> HCertValidity {
      let certType = certificationType(for: certificate.certificateType)
      if let countryCode = certificate.ruleCountryCode {
        let valueSets = DataCenter.localDataManager.getValueSetsForExternalParameters()
        let filterParameter = FilterParameter(validationClock: Date(),
            countryCode: countryCode,
            certificationType: certType)
        let externalParameters = ExternalParameter(validationClock: Date(),
           valueSets: valueSets,
           exp: certificate.exp,
           iat: certificate.iat,
           issuerCountryCode: certificate.issCode,
           kid: certificate.kidStr)
        let result = CertLogicManager.shared.validateTraveller(filter: filterParameter,
            external: externalParameters, payload: certificate.body.description)
        
        let fails = result.filter { $0.result == .fail }
        if !fails.isEmpty {
          return .invalid
        }
        let open = result.filter { $0.result == .open }
        if !open.isEmpty {
          return .ruleInvalid
        }
      }
      return .valid
    }
    
    private func certificationType(for type: SwiftDGC.HCertType) -> CertificateType {
      switch type {
      case .recovery:
        return .recovery
      case .test:
        return .test
      case .vaccine:
        return .vaccination
      case .unknown:
        return .general
      }
    }
}
