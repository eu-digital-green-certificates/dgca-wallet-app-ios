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
//  CertificatesListVC.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 21.09.2021.
//  

import UIKit
import SwiftDGC

class CertificatesListVC: UIViewController {
  
  private enum Constants {
    static let hcertCellIndentifier = "CertificateCell"
  }
  
  @IBOutlet weak var tableView      : UITableView!
  @IBOutlet weak var nextButton     : UIButton!
  
  private var listOfCert = [DatedCertString]()
  private var validationServiceInfo : ServerListResponse?
  private var accessTokenInfo       : AccessTokenResponse?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.tableFooterView = UIView()
    title = l10n("certificates")
    tableView.reloadData()
  }
  
  @IBAction func nextButtonAction(_ sender: Any) {
    guard let tokenInfo = accessTokenInfo,
          let serviceInfo = validationServiceInfo,
          let selectedCert = self.getSelectedCert()?.cert
    else { return }
    
    let vc = TicketCodeAcceptViewController()
    
    vc.setCertsWith(serviceInfo, tokenInfo, selectedCert)
    self.navigationController?.pushViewController(vc, animated: true)
  }
  
  public func setCertsWith(_ validationInfo: ServerListResponse,_ accessTokenModel : AccessTokenResponse) {
    // TODO: Make filtering by all predicates (dob, validFrom/To, fullName)
        
    validationServiceInfo = validationInfo
    accessTokenInfo = accessTokenModel
        
    listOfCert = LocalData.sharedInstance.certStrings.filter { ($0.cert!.fullName.lowercased() == "\(accessTokenModel.vc?.gnt ?? "") + \(accessTokenModel.vc?.fnt ?? "")".lowercased()) || ($0.cert!.dateOfBirth == accessTokenModel.vc?.dob) }
  }
  
  private func deselectAllCert() {
    for i in 0..<listOfCert.count {
        listOfCert[i].isSelected = false
    }
  }
  
  public func getSelectedCert() -> DatedCertString? {
     return listOfCert.filter({ $0.isSelected }).first
  }
}

extension CertificatesListVC: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return listOfCert.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

  // Override to support editing the table view.
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
      if editingStyle == .delete {
        let savedCert = listOfCert[indexPath.row]
        showAlert(title: l10n("cert.delete.title"), subtitle: l10n("cert.delete.body"), actionTitle: l10n("btn.confirm"),
         cancelTitle: l10n("btn.cancel")) { [weak self] in
             if $0 {
               tableView.endUpdates()
               self?.listOfCert.remove(at: indexPath.row)
               LocalData.remove(withTAN: savedCert.storedTAN)
               LocalData.sharedInstance.save()
               tableView.beginUpdates()
               DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
               tableView.reloadData()
             }
           }
         }
      }
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      deselectAllCert()
      listOfCert[indexPath.row].isSelected = true
      tableView.reloadRows(at: [indexPath], with: .automatic)
  }
}
