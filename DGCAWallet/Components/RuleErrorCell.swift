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
//  RuleErrorCell.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 05.07.2021.
//  

import UIKit
import SwiftDGC

class RuleErrorCell: UITableViewCell {
  @IBOutlet fileprivate weak var ruleLabel: UILabel!
  @IBOutlet fileprivate weak var ruleValueLabel: UILabel!
  @IBOutlet fileprivate weak var currentLabel: UILabel!
  @IBOutlet fileprivate weak var currentValueLabel: UILabel!
  @IBOutlet fileprivate weak var resultLabel: UILabel!
  @IBOutlet fileprivate weak var resultValueLabel: UILabel!
  @IBOutlet fileprivate weak var failedLabel: UILabel!
    
  private var infoItem: InfoSection? {
    didSet {
      setupView()
    }
  }

  override func prepareForReuse() {
    setLabels()
  }
    
  private func setLabels() {
    ruleLabel.text = l10n("Rule")
    ruleValueLabel.text = ""
    currentLabel.text = l10n("Current")
    currentValueLabel.text = ""
    resultLabel.text = l10n("Result")
    resultValueLabel.text = ""
  }
    
  private func setupView() {
    guard let infoItem = infoItem else { return }
    ruleValueLabel.text = infoItem.header
    currentValueLabel.text = infoItem.content
    switch infoItem.ruleValidationResult {
    case .error:
      failedLabel.textColor = .walletRed
      failedLabel.text = l10n("Failed")
    case .passed:
      failedLabel.textColor = .walletGreen
      failedLabel.text = l10n("Passed")
    case .open:
      failedLabel.textColor = .walletGreen
      failedLabel.text = l10n("Open")
    }

    if let countryName = infoItem.countryName {
      switch infoItem.ruleValidationResult {
      case .error:
        resultValueLabel.text = String(format: l10n("Failed for %@ (see settings)"), countryName)
      case .passed:
        resultValueLabel.text = String(format: l10n("Passed for %@ (see settings)"), countryName)
      case .open:
        resultValueLabel.text = String(format: l10n("Open for %@ (see settings)"), countryName)
      }
    } else {
      switch infoItem.ruleValidationResult {
      case .error:
        resultValueLabel.text = l10n("Failed")
      case .passed:
        resultValueLabel.text = l10n("Passed")
      case .open:
        resultValueLabel.text = l10n("Open")
      }
    }
  }
    
  func setupCell(with info: InfoSection) {
    self.infoItem = info
  }
}
