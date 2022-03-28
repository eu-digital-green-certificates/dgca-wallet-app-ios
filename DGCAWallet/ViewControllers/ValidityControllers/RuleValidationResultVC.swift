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
//  RuleValidationResultVC.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 08.07.2021.
//  
        

import UIKit
import SwiftDGC
import CertLogic

public typealias OnCloseHandler = () -> Void

class RuleValidationResultVC: UIViewController {
  private enum Constants {
    static let ruleCellId = "RuleErrorCell"
  }
  
  @IBOutlet fileprivate weak var closeButton: UIButton!
  @IBOutlet fileprivate weak var okButton: UIButton!
  @IBOutlet fileprivate weak var resultLabel: UILabel!
  @IBOutlet fileprivate weak var resultIcon: UIImageView!
  @IBOutlet fileprivate weak var resultDescriptionLabel: UILabel!
  @IBOutlet fileprivate weak var noWarrantyLabel: UILabel!
  @IBOutlet fileprivate weak var tableView: UITableView!
 
  var closeHandler: OnCloseHandler?

  private var hCert: HCert?
  private var selectedDate = Date()
  private var items: [InfoSection] = []
    
  override func viewDidLoad() {
    super.viewDidLoad()
    setupInterface()
  }
  
  func setupRuleValidation(with hcert: HCert, selectedDate: Date) {
    self.hCert = hcert
    self.selectedDate = selectedDate
  }
    
  private func setupInterface() {
    resultLabel.text = "Validating certificate with country rules".localized
    resultDescriptionLabel.text = ""
    noWarrantyLabel.text = "This check gives an indication on eligibility...".localized
    closeButton.setTitle("Close".localized, for: .normal)
    okButton.setTitle("OK".localized, for: .normal)
    tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 32, right: 0)

    let validity: HCertValidity = self.validateCertLogicRules()
    switch validity {
      case .valid:
      resultLabel.text = "Valid certificate".localized
      resultDescriptionLabel.text = "Your certificate is valid and confirms...".localized
        resultIcon.image = UIImage(named: "icon_large_valid")
      case .invalid:
      resultLabel.text = "Invalid certificate".localized
      resultDescriptionLabel.text = "Your certificate did not allows you to enter the chosen country".localized
      case .ruleInvalid:
      resultLabel.text = "Certificate has limitation".localized
      resultDescriptionLabel.text = "Your certificate is valid but has the following restrictions:".localized
        resultIcon.image = UIImage(named: "icon_large_warning")
    case .revoked:
      resultLabel.text = "Certificate was revoked".localized
      resultDescriptionLabel.text = "Your certificate did not allows you to enter the chosen country".localized
        resultIcon.image = UIImage(named: "icon_large_warning")

    }
    resultIcon.isHidden = false
    tableView.isHidden = false
    noWarrantyLabel.isHidden = false
    resultDescriptionLabel.sizeToFit()
    noWarrantyLabel.sizeToFit()
  }
    
  @IBAction func closeAction(_ sender: Any) {
    dismiss(animated: true) { [weak self] in
      self?.closeHandler?()
    }
  }
}

extension RuleValidationResultVC: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    // Please uncomment this if you need to show message about no rules for selected country
//    if items.count == 0 {
//      self.tableView.setEmptyMessage("Sorry! \n no rules for this country")
//    } else {
//      self.tableView.restore()
//    }
    return items.count
  }
    
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.ruleCellId, for: indexPath) as? RuleErrorCell else { return UITableViewCell() }
    let item: InfoSection = items[indexPath.row]
    cell.setupCell(with: item)
    return cell
  }
}

extension RuleValidationResultVC {
  private func validateCertLogicRules() -> HCertValidity {
    var validity: HCertValidity = .valid
    guard let hCert = hCert else { return validity }
      
    let certType = getCertificationType(type: hCert.certificateType)
    if let countryCode = hCert.ruleCountryCode {
      let valueSets = DataCenter.localDataManager.getValueSetsForExternalParameters()
      let filterParameter = FilterParameter(validationClock: self.selectedDate,
        countryCode: countryCode,
        certificationType: certType)
      let externalParameters = ExternalParameter(validationClock: self.selectedDate,
         valueSets: valueSets,
         exp: hCert.exp,
         iat: hCert.iat,
         issuerCountryCode: hCert.issCode,
         kid: hCert.kidStr)
      let result = CertLogicManager.shared.validate(filter: filterParameter,
        external: externalParameters, payload: hCert.body.description)
        
      let failsAndOpen = result.filter { $0.result != .passed }
      if failsAndOpen.count > 0 {
        validity = .ruleInvalid
        result.sorted(by: { $0.result.rawValue < $1.result.rawValue }).forEach { validationResult in
          if let error = validationResult.validationErrors?.first {
            switch validationResult.result {
            case .fail:
              items.append(InfoSection(header: "Certificate logic engine error".localized, content: error.localizedDescription,
                countryName: hCert.ruleCountryCode,
                ruleValidationResult: .invalid))
            case .open:
              items.append(InfoSection(header: "Certificate logic engine error".localized, content: error.localizedDescription,
                countryName: hCert.ruleCountryCode,
                ruleValidationResult: .ruleInvalid))
            case .passed:
              items.append(InfoSection(header: "Certificate logic engine error".localized, content: error.localizedDescription,
                countryName: hCert.ruleCountryCode,
                ruleValidationResult: .valid))
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
               let dict = CertLogicManager.shared.getRuleDetailsError(rule: rule,
                filter: filterParameter)
              dict.keys.forEach({ key in
                detailsError += key + ": " + (dict[key] ?? "") + " "
              })
            }
            switch validationResult.result {
            case .fail:
              items.append(InfoSection(header: errorString,
                content: detailsError,
                countryName: hCert.ruleCountryCode,
                ruleValidationResult: .invalid))
            case .open:
              items.append(InfoSection(header: errorString,
                content: detailsError,
                countryName: hCert.ruleCountryCode,
                ruleValidationResult: .ruleInvalid))
            case .passed:
              items.append(InfoSection(header: errorString,
                content: detailsError,
                countryName: hCert.ruleCountryCode,
                ruleValidationResult: .valid))
            }
          }
        }
        self.tableView.reloadData()
      }
    }
    return validity
  }
}

// MARK: External CertType from HCert type
extension RuleValidationResultVC {
  private func getCertificationType(type: SwiftDGC.HCertType) -> CertificateType {
    var certType: CertificateType = .general
    switch type {
    case .recovery:
      certType = .recovery
    case .test:
      certType = .test
    case .vaccine:
      certType = .vaccination
    case .unknown:
      certType = .general
    }
    return certType
  }
}
