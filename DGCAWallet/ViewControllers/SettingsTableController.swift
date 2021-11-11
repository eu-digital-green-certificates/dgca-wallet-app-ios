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
//  SettingsTableController.swift
//  DGCAWallet
//  
//  Created by Paul Ballmann on 14.05.21.
//  


import UIKit
import SwiftDGC


class SettingsTableController: UITableViewController {

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.row == 0 {
      openPrivacyDoc()
    } else if indexPath.row == 1 {
      showLicenses()
    }
    tableView.deselectRow(at: indexPath, animated: true)
  }

  @IBAction func doneAction(_ sender: Any) {
    self.dismiss(animated: true)
  }

  func openPrivacyDoc() {
    let link = DataCenter.localDataManager.versionedConfig["privacyUrl"].string ?? ""
    openUrl(link)
  }

  func openEuCertDoc() {
    let link = "https://ec.europa.eu/health/ehealth/covid-19_en"
    openUrl(link)
  }

  func showLicenses() {
    self.performSegue(withIdentifier: "showLicenses", sender: nil)
  }
  
  func openUrl(_ string: String) {
    if let url = URL(string: string) {
      UIApplication.shared.open(url)
    }
  }
}
