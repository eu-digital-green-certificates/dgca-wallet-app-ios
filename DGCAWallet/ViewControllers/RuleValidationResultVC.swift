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

final class RuleValidationResultVC: UIViewController {

  private enum Constants {
    static let ruleCellId = "RuleErrorTVC"
  }
  
  @IBOutlet weak var closeButton: UIButton!
  @IBOutlet weak var resultLabel: UILabel!
  @IBOutlet weak var resultIcon: UIImageView!
  @IBOutlet weak var resultDescriptionLabel: UILabel!
  @IBOutlet weak var noWarrantyLabel: UILabel!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
  private var hCert: HCert?
  private var selectedDate = Date()
  var closeHandler: OnCloseHandler?
  var items: [InfoSection] = []
    
  override func viewDidLoad() {
    super.viewDidLoad()
    setupLabels()
    setupTableView()
    activityIndicator.startAnimating()
  }

  private func setupTableView() {
    tableView.dataSource = self
    tableView.register(UINib(nibName: Constants.ruleCellId, bundle: nil),
        forCellReuseIdentifier: Constants.ruleCellId)
    tableView.contentInset = .init(top: 0, left: 0, bottom: 32, right: 0)
  }
    
  private func setupLabels() {
    resultLabel.text = l10n("validate_certificate_with_rules")
    resultDescriptionLabel.text = ""
    noWarrantyLabel.text = l10n("info_without_waranty")
    closeButton.setTitle(l10n("close"), for: .normal)
  }
    
  @IBAction func closeAction(_ sender: Any) {
    dismiss(animated: true) { [weak self] in
      self?.closeHandler?()
    }
  }

  func setupView(with hcert: HCert, selectedDate: Date) {
    self.hCert = hcert
    self.selectedDate = selectedDate
    let validity: HCertValidity = self.validateCertLogicRules()
    switch validity {
      case .valid:
          resultLabel.text = l10n("valid_certificate")
          resultDescriptionLabel.text = l10n("your_certificate_allow")
          resultIcon.image = UIImage(named: "icon_large_valid")
      case .invalid:
          resultLabel.text = l10n("invalid_certificate")
          resultDescriptionLabel.text = l10n("your_certificate_did_not_allow")
      case .ruleInvalid:
          resultLabel.text = l10n("certificate_limitation")
          resultDescriptionLabel.text = l10n("certification_has_limitation")
          resultIcon.image = UIImage(named: "icon_large_warning")
    }

    activityIndicator.stopAnimating()
    resultIcon.isHidden = false
    tableView.isHidden = false
    noWarrantyLabel.isHidden = false
    resultDescriptionLabel.sizeToFit()
    noWarrantyLabel.sizeToFit()
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
    let item: InfoSection = items[indexPath.row]
    guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.ruleCellId, for: indexPath) as? RuleErrorTVC else { return UITableViewCell() }
      
    cell.setupCell(with: item)
    return cell
  }
}

extension RuleValidationResultVC {
  func validateCertLogicRules() -> HCertValidity {
    var validity: HCertValidity = .valid
    guard let hCert = hCert else { return validity }
      
    let certType = getCertificationType(type: hCert.type)
    if let countryCode = hCert.ruleCountryCode {
      let valueSets = ValueSetsDataStorage.sharedInstance.getValueSetsForExternalParameters()
      let filterParameter = FilterParameter(validationClock: self.selectedDate,
        countryCode: countryCode,
        certificationType: certType)
      let externalParameters = ExternalParameter(validationClock: self.selectedDate,
         valueSets: valueSets,
         exp: hCert.exp,
         iat: hCert.iat,
         issuerCountryCode: hCert.issCode,
         kid: hCert.kidStr)
      let result = CertLogicEngineManager.sharedInstance.validate(filter: filterParameter,
        external: externalParameters, payload: hCert.body.description)
      let failsAndOpen = result.filter { validationResult in return validationResult.result != .passed }
      if failsAndOpen.count > 0 {
        validity = .ruleInvalid
        result.sorted(by: { vdResultOne, vdResultTwo in
          vdResultOne.result.rawValue < vdResultTwo.result.rawValue
        }).forEach { validationResult in
          if let error = validationResult.validationErrors?.first {
            switch validationResult.result {
            case .fail:
              items.append(InfoSection(header: "CirtLogic Engine error",
                                                    content: error.localizedDescription,
                                                    countryName: hCert.ruleCountryCode,
                                                    ruleValidationResult: SwiftDGC.RuleValidationResult.error))
            case .open:
              items.append(InfoSection(header: "CirtLogic Engine error",
                                                    content: error.localizedDescription,
                                                    countryName: hCert.ruleCountryCode,
                                                    ruleValidationResult: SwiftDGC.RuleValidationResult.open))
            case .passed:
              items.append(InfoSection(header: "CirtLogic Engine error",
                                                    content: error.localizedDescription,
                                                    countryName: hCert.ruleCountryCode,
                                                    ruleValidationResult: SwiftDGC.RuleValidationResult.passed))
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
               let dict = CertLogicEngineManager.sharedInstance.getRuleDetailsError(rule: rule,
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
                                                    ruleValidationResult: SwiftDGC.RuleValidationResult.error))
            case .open:
              items.append(InfoSection(header: errorString,
                                                    content: detailsError,
                                                    countryName: hCert.ruleCountryCode,
                                                    ruleValidationResult: SwiftDGC.RuleValidationResult.open))
            case .passed:
              items.append(InfoSection(header: errorString,
                                                    content: detailsError,
                                                    countryName: hCert.ruleCountryCode,
                                                    ruleValidationResult: SwiftDGC.RuleValidationResult.passed))
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
  func getCertificationType(type: SwiftDGC.HCertType) -> CertificateType {
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
