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
//  CertificateListController.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 21.09.2021.
//  

import UIKit
import SwiftDGC

class CertificateListController: UIViewController {
  private enum Constants {
    static let hcertCellIndentifier = "CertificateCell"
    static let showTicketAcceptController = "showTicketAcceptController"
    static let accessTokenCellInfoIdentifier = "AccessTokenInfoCell"
  }
  
  @IBOutlet fileprivate weak var tableView: UITableView!
  @IBOutlet fileprivate weak var nextButton: UIButton!
  
  private var listOfCert = [DatedCertString]()
  private var validationServiceInfo : ServerListResponse?
  private var accessTokenInfo       : AccessTokenResponse?
  private var accessTokenInfoKeys   : [String] = ["Name", "Date of birth", "Departure","Arrival","Accepted certificate type","Category","Validation Time","Valid from","Valid to"]
  private var accessTokenInfoValues   : [String] = [String]()
  
  private var isNavigationEnabled: Bool {
    return accessTokenInfo != nil && validationServiceInfo != nil && getSelectedCert()?.cert != nil
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    guard let vcValue = accessTokenInfo?.vc else { return }
    accessTokenInfoValues = ["\(vcValue.gnt!) \(vcValue.fnt!)", vcValue.dob!, "\(vcValue.cod!),\(vcValue.rod!)", "\(vcValue.coa!),\(vcValue.roa!)", vcValue.type!.joined(separator: ","), vcValue.category!.joined(separator: ","), vcValue.validationClock!, vcValue.validFrom!, vcValue.validTo!]
    
    tableView.tableFooterView = UIView()
    title = l10n("certificates")
    nextButton.isEnabled = false
    nextButton.backgroundColor = UIColor.walletLightYellow
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    tableView.reloadData()
  }

  @IBAction func nextButtonAction(_ sender: Any) {
    guard isNavigationEnabled else { return }
    self.performSegue(withIdentifier: Constants.showTicketAcceptController, sender: nil)
  }
  
  func setCertsWith(_ validationInfo: ServerListResponse, _ accessTokenModel : AccessTokenResponse) {
    validationServiceInfo = validationInfo
    accessTokenInfo = accessTokenModel
    
    listOfCert = DataCenter.certStrings.filter { ($0.cert!.fullName.lowercased() == "\(accessTokenModel.vc!.gnt!) \(accessTokenModel.vc!.fnt!)".lowercased()) && ($0.cert!.dateOfBirth == accessTokenModel.vc?.dob)}
    let validDateFrom = accessTokenModel.vc?.validFrom ?? ""
    if let dateValidFrom = Date(rfc3339DateTimeString: validDateFrom) {
      listOfCert = listOfCert.filter{ $0.cert!.iat < dateValidFrom }
    }
    let validDateTo = accessTokenModel.vc?.validTo ?? ""
    if let dateValidUntil = Date(rfc3339DateTimeString: validDateTo ) {
      listOfCert = listOfCert.filter {$0.cert!.exp > dateValidUntil }
    }
  }
  
  func reloadComponents() {
    guard let accessTokenModel = accessTokenInfo else { return }
          accessTokenInfo = accessTokenModel

    listOfCert = DataCenter.certStrings.filter { ($0.cert!.fullName.lowercased() == "\(accessTokenModel.vc!.gnt!) \(accessTokenModel.vc!.fnt!)".lowercased()) && ($0.cert!.dateOfBirth == accessTokenModel.vc?.dob)}
    let validDateFrom = accessTokenModel.vc!.validFrom ?? ""
    if let dateValidFrom = Date(rfc3339DateTimeString: validDateFrom) {
      listOfCert = listOfCert.filter{ $0.cert!.iat < dateValidFrom }
    }
    let validDateTo = accessTokenModel.vc!.validTo ?? ""
    if let dateValidUntil = Date(rfc3339DateTimeString: validDateTo ) {
      listOfCert = listOfCert.filter {$0.cert!.exp > dateValidUntil }
    }
  }
  
  private func deselectAllCert() {
    for i in 0..<listOfCert.count {
        listOfCert[i].isSelected = false
    }
  }
  
  private func getSelectedCert() -> DatedCertString? {
     return listOfCert.filter({ $0.isSelected }).first
  }
}

extension CertificateListController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      if self.accessTokenInfo?.t == 0 {
        return 0
      } else if self.accessTokenInfo?.t == 1 {
        return 2
      } else if self.accessTokenInfo?.t == 2 {
        return 9
      }
    }
      return listOfCert.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.accessTokenCellInfoIdentifier,
          for: indexPath) as? TokenInfoCell else { return UITableViewCell() }
      
      cell.fieldName.text = accessTokenInfoKeys[indexPath.row]
      cell.fieldValue.text = accessTokenInfoValues[indexPath.row]
      
      return cell
    }
      guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.hcertCellIndentifier,
          for: indexPath) as? CertificateCell else { return UITableViewCell() }
      let savedCert = listOfCert[indexPath.row]

      cell.accessoryType = savedCert.isSelected ? .checkmark : .none
      if let cert = savedCert.cert {
          cell.setCertificate(cert: cert)
      }
      return cell
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let savedCert = listOfCert[indexPath.row]
      showAlert(title: l10n("cert.delete.title"), subtitle: l10n("cert.delete.body"), actionTitle: l10n("btn.confirm"),
       cancelTitle: l10n("btn.cancel")) {
          if $0 {
           DataCenter.localDataManager.remove(withDate: savedCert.date) { [weak self] _ in
             self?.reloadComponents()
             DispatchQueue.main.asyncAfter(deadline: .now()) {
               tableView.reloadData()
             }
           }
         }
       }
    }
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 1 {
      deselectAllCert()
      nextButton.isEnabled = true
      nextButton.backgroundColor = UIColor.walletYellow
      listOfCert[indexPath.row].isSelected = true
      tableView.reloadData()
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier {
    case Constants.showTicketAcceptController:
      guard let ticketController = segue.destination as? TicketCodeAcceptViewController,
          let tokenInfo = accessTokenInfo,
          let serviceInfo = validationServiceInfo,
          let selectedCert = getSelectedCert()?.cert else { return }
      
      ticketController.setCertsWith(serviceInfo, tokenInfo, selectedCert)

    default:
        break
    }
  }
}
