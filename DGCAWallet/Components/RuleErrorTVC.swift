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
//  RuleErrorTVC.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 05.07.2021.
//  

import UIKit
import SwiftDGC

class RuleErrorTVC: UITableViewCell {

  @IBOutlet weak var ruleLabel: UILabel!
  @IBOutlet weak var ruleValueLabel: UILabel!
  @IBOutlet weak var currentLabel: UILabel!
  @IBOutlet weak var currentValueLabel: UILabel!
  @IBOutlet weak var resultLabel: UILabel!
  @IBOutlet weak var resultValueLabel: UILabel!
  @IBOutlet weak var failedLabel: UILabel!
  private var infoItem: InfoSection? {
    didSet {
      setupView()
    }
  }

  override func prepareForReuse() {
    setLabels()
  }
    
  private func setLabels() {
    ruleLabel.text = l10n("rule")
    ruleValueLabel.text = ""
    currentLabel.text = l10n("current")
    currentValueLabel.text = ""
    resultLabel.text = l10n("result")
    resultValueLabel.text = ""
  }
    
  private func setupView() {
    guard let infoItem = infoItem else { return }
    ruleValueLabel.text = infoItem.header
    currentValueLabel.text = infoItem.content
    switch infoItem.ruleValidationResult {
    case .error:
      failedLabel.textColor = .red
      failedLabel.text = l10n("failed")
    case .passed:
      failedLabel.textColor = .green
      failedLabel.text = l10n("passed")
    case .open:
      failedLabel.textColor = .green
      failedLabel.text = l10n("open")
    }

    if let countryName = infoItem.countryName {
      switch infoItem.ruleValidationResult {
      case .error:
        resultValueLabel.text = String(format: l10n("failed_for_country"), countryName)
      case .passed:
        resultValueLabel.text = String(format: l10n("passed_for_country"), countryName)
      case .open:
        resultValueLabel.text = String(format: l10n("open_for_country"), countryName)
      }
    } else {
      switch infoItem.ruleValidationResult {
      case .error:
        resultValueLabel.text = l10n("failed")
      case .passed:
        resultValueLabel.text = l10n("passed")
      case .open:
        resultValueLabel.text = l10n("open")
      }
    }
  }
  public func setupCell(with info: InfoSection) {
    self.infoItem = info
  }
}
