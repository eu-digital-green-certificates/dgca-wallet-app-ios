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
    static let showTicketAcceptController = "showTicketAcceptController"
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
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    tableView.reloadData()
  }

  @IBAction func nextButtonAction(_ sender: Any) {
    self.performSegue(withIdentifier: Constants.showTicketAcceptController, sender: nil)
  }
  
  func setCertsWith(_ validationInfo: ServerListResponse,_ accessTokenModel : AccessTokenResponse) {
    // TODO: Make filtering by all predicates (dob, validFrom/To, fullName)
        
    validationServiceInfo = validationInfo
    accessTokenInfo = accessTokenModel
    let firstName = accessTokenModel.vc?.gnt?.lowercased() ?? ""
    let lastName = accessTokenModel.vc?.fnt?.lowercased() ?? ""
    let ticketingFullName: String
    
    listOfCert = LocalData.sharedInstance.certStrings.filter { ($0.cert!.fullName.lowercased() == "\(accessTokenModel.vc!.gnt!) \(accessTokenModel.vc!.fnt!)".lowercased()) && ($0.cert!.dateOfBirth == accessTokenModel.vc?.dob)}
    if let dateValidFrom = Date(rfc3339DateTimeString: accessTokenModel.vc!.validFrom ?? "") {
      listOfCert = listOfCert.filter{ $0.cert!.iat < dateValidFrom }
    }
    
    if let dateValidUntil = Date(rfc3339DateTimeString: accessTokenModel.vc!.validTo ?? "") {
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
               LocalData.remove(withDate: savedCert.date)
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
  

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 90.0
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
