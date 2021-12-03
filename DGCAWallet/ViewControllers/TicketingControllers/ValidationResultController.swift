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
//  ValidationResultController.swift
//  DGCAWallet
//  
//  Created by Illia Vlasov on 20.10.2021.
//  


import UIKit
import SwiftDGC

class ValidationResultController: UIViewController {
  @IBOutlet fileprivate weak var titleLabel: UILabel!
  @IBOutlet fileprivate weak var iconImage: UIImageView!
  @IBOutlet fileprivate weak var detailLabel: UILabel!
  @IBOutlet fileprivate weak var limitationsTableView: UITableView!
  @IBOutlet fileprivate weak var okButton: UIButton!

  public var accessTokenResponse : AccessTokenResponse?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }
  
  private func setupUI() {
    limitationsTableView.reloadData()
    limitationsTableView.tableFooterView = UIView()
    iconImage.image = iconImage.image?.withRenderingMode(.alwaysTemplate)
    okButton.setTitle("OK".localized, for: .normal)

    guard let result = accessTokenResponse?.result else {
      showInfoAlert(withTitle: "Cannot validate the certificate".localized,
        message: "Make sure you select the desired service...".localized)
      
      titleLabel.text = "Validation error".localized
      detailLabel.text = "Please refer to the Re-open EU website.".localized
      iconImage.image = UIImage(named: "icon_large_invalid")
      iconImage.tintColor = .walletRed
      return
    }
    
    switch result {
    case "OK":
      titleLabel.text = "Valid certificate".localized
      detailLabel.text = "Your certificate is valid and confirms...".localized
      iconImage.image = UIImage(named: "icon_large_valid")
      iconImage.tintColor = .walletGreen
        
    case "NOK":
      titleLabel.text = "Invalid certificate".localized
      detailLabel.text = "Your certificate is not valid. Please refer to the Re-open EU website:".localized
      iconImage.image = UIImage(named: "icon_large_invalid")
      iconImage.tintColor = .walletRed
        
    case "CHK":
      titleLabel.text = "Certificate has limitation".localized
      detailLabel.text = "Your certificate is valid but has the following restrictions:".localized
      iconImage.image = UIImage(named: "icon_large_warning")
      iconImage.tintColor = .walletYellow
        
    default:
      titleLabel.text = "Invalid certificate".localized
      detailLabel.text = "Your certificate is not valid. Please refer to the Re-open EU website:".localized
      iconImage.image = UIImage(named: "icon_large_invalid")
      iconImage.tintColor = .walletRed
    }
  }
  
  @IBAction func onAccept(_ sender: Any) {
    self.navigationController?.popToRootViewController(animated: true)
  }
}

extension ValidationResultController : UITableViewDelegate, UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let issuesCount = accessTokenResponse?.results?.count else { return 0 }
    return issuesCount
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "LimitationCell", for: indexPath) as! LimitationCell
    cell.issueTextView.text = accessTokenResponse?.results?[indexPath.row].details ?? ""
    return cell
  }
}
