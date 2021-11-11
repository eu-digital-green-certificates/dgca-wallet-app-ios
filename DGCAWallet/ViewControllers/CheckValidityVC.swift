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
//  CheckValidityVC.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 08.07.2021.
//  
        

import UIKit
import SwiftDGC

final class CheckValidityVC: UIViewController {
  private enum Constants {
    static let titleCellIndentifier = "CellWithTitleAndDescriptionTVC"
    static let countryCellIndentifier = "CellWithDateAndCountryTVC"
    static let showRuleValidationResult = "showRuleValidationResult"
    static let bottomOffset: CGFloat = 32.0
  }
  
  @IBOutlet fileprivate weak var closeButton: UIButton!
  @IBOutlet fileprivate weak var checkValidityButton: UIButton!
  @IBOutlet fileprivate weak var tableView: UITableView!
    
  private var items: [ValidityCellModel] = []
  private var hCert: HCert?
  private var selectedDate = Date()
    
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    checkValidityButton.setTitle(l10n("button_i_agree"), for: .normal)
    closeButton.setTitle(l10n("close"), for: .normal)
  }
    
  @IBAction func closeButtonAction(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
    
  private func setupView() {
    setupInitialDate()
    tableView.contentInset = .init(top: .zero, left: .zero, bottom: Constants.bottomOffset, right: .zero)
    tableView.reloadData()
  }
    
  private func setupTableView() {
    tableView.contentInset = .init(top: .zero, left: .zero, bottom: Constants.bottomOffset, right: .zero)
  }
    
  private func setupInitialDate() {
    items.append(ValidityCellModel(title: l10n("country_certificate_text"), description: "",
        needChangeTitleFont: true))
    items.append(ValidityCellModel(cellType: .countryAndTimeSelection))
    items.append(ValidityCellModel(title: l10n("disclaimer"), description: l10n("disclaimer_text")))
  }
    
  func setupCheckValidity(with cert: HCert?) {
    self.hCert = cert
  }
    
  @IBAction func checkValidityAction(_ sender: Any) {
    performSegue(withIdentifier: Constants.showRuleValidationResult, sender: nil)
  }
}

extension CheckValidityVC: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let item: ValidityCellModel = items[indexPath.row]
    if item.cellType == .titleAndDescription {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.titleCellIndentifier,
          for: indexPath) as? CellWithTitleAndDescriptionTVC else { return UITableViewCell() }

      cell.setupCell(with: item)
      return cell
        
    } else {
      guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.countryCellIndentifier, for: indexPath) as? CellWithDateAndCountryTVC else { return UITableViewCell() }

      cell.countryHandler = { [weak self] countryCode in
        self?.hCert?.ruleCountryCode = countryCode
      }
      cell.dataHandler = {[weak self] date in
        self?.selectedDate = date
      }
      cell.setupView()
      return cell
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier {
    case Constants.showRuleValidationResult:
      guard let validationController = segue.destination as? RuleValidationResultVC, let hCert = hCert else { return }
      validationController.closeHandler = { self.closeButtonAction(self) }
      validationController.setupRuleValidation(with: hCert, selectedDate: self.selectedDate)

    default:
      break
    }
  }
}
