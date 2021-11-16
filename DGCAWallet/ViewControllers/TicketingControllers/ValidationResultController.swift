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

enum ValidationResultType {
  case valid
  case invalid
  case open
}

class ValidationResultController: UIViewController {
  
  @IBOutlet fileprivate weak var titleLabel: UILabel!
  @IBOutlet fileprivate weak var iconImage: UIImageView!
  @IBOutlet fileprivate weak var detailLabel: UILabel!
  @IBOutlet fileprivate weak var limitationsTableView: UITableView!
  
  public var validationResultModel : AccessTokenResponse?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }
  
  private func setupUI() {
    limitationsTableView.reloadData()
    limitationsTableView.tableFooterView = UIView()
    iconImage.image = iconImage.image?.withRenderingMode(.alwaysTemplate)
    
    switch validationResultModel?.result {
    case "OK":
      titleLabel.text = "Valid certificate"
      detailLabel.text = "Your certificate is valid and confirms to the provided country rules. Additional entry requirements might apply, please refer to the Re-open EU website:"
      iconImage.image = UIImage(named: "icon_large_valid")
      
      iconImage.tintColor = .walletGreen
    case "NOK":
      titleLabel.text = "Invalid certificate"
      detailLabel.text = "Your certificate is not valid. Please refer to the Re-open EU website:"
      iconImage.image = UIImage(named: "icon_large_invalid")
      
      iconImage.tintColor = .walletRed
    case "CHK":
      titleLabel.text = "Certificate has limitation"
      detailLabel.text = "Your certificate is valid but has the following restrictions:"
      iconImage.image = UIImage(named: "icon_large_warning")
      
      iconImage.tintColor = .yellow
    case .none:
      titleLabel.text = "Invalid certificate"
      detailLabel.text = "Your certificate is not valid. Please refer to the Re-open EU website:"
      iconImage.image = UIImage(named: "icon_large_invalid")
      iconImage.tintColor = .walletRed
    case .some(_):
      titleLabel.text = "Invalid certificate"
      detailLabel.text = "Your certificate is not valid. Please refer to the Re-open EU website:"
      iconImage.image = UIImage(named: "icon_large_invalid")
      iconImage.tintColor = .walletRed
    }
  }
  
  @IBAction func onAccept(_ sender: Any) {
    self.navigationController?.popToRootViewController(animated: true)
  }
}

extension ValidationResultController : UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let issuesCount = validationResultModel?.results?.count else { return 0 }
    return issuesCount
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "LimitationCell", for: indexPath) as! LimitationCell
    if let issueText = validationResultModel?.results?[indexPath.row].details {
      cell.issueTextView.text = issueText
    }
    return cell
  }
}

extension ValidationResultController : UITableViewDelegate {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
}
