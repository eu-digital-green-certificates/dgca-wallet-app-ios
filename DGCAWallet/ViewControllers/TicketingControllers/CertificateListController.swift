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
import DCCInspection

class CertificateListController: UIViewController {
  let showTicketAcceptController = "showTicketAcceptController"
  
  @IBOutlet fileprivate weak var tableView: UITableView!
  @IBOutlet fileprivate weak var nextButton: UIButton!
  
  var ticketingAcceptance: TicketingAcceptance?
  
  private var stringCertificates = [DatedCertString]()
  private var selectedStringCertificate: DatedCertString? {
    return stringCertificates.filter({ $0.isSelected }).first
  }
    
  private var isNavigationEnabled: Bool {
    return ticketingAcceptance != nil && selectedStringCertificate?.cert != nil
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    tableView.tableFooterView = UIView()
    title = "Certificates".localized
    nextButton.setTitle("Next".localized, for: .normal)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.stringCertificates = ticketingAcceptance?.ticketingCertificates ?? []
    tableView.reloadData()
  }
  
  @IBAction func nextButtonAction(_ sender: Any) {
    guard let _ = selectedStringCertificate?.cert else {
      self.showInfoAlert(withTitle: "Please select a certificate".localized,
          message: "Here are all the appropriate certificates.".localized)
        return
    }
    self.performSegue(withIdentifier: showTicketAcceptController, sender: nil)
  }
    
  private func deselectAllCertificates() {
    for i in 0..<stringCertificates.count {
      stringCertificates[i].isSelected = false
    }
  }
}

extension CertificateListController: UITableViewDataSource, UITableViewDelegate {
  func numberOfSections(in tableView: UITableView) -> Int {
    return stringCertificates.isEmpty ? 1 : 2
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      guard let infoTableValue = ticketingAcceptance?.accessInfo.t else { return 0 }

      switch infoTableValue {
      case 0:
        return 0
      case 1:
        return 2
      case 2:
        return 9
      default:
        return 0
      }
      
    } else {
      return stringCertificates.count
    }
  }
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if section == 0 {
      return "Ticketing information".localized
    } else {
      return "Available Certificates".localized
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      let cellID = String(describing: TokenInfoCell.self)
      guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? TokenInfoCell
      else { return UITableViewCell() }
      
      cell.certificateRecord = ticketingAcceptance?.certificateRecords[indexPath.row]
      return cell
      
    } else {
      let cellID = String(describing: CertificateCell.self)
      guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? CertificateCell
      else { return UITableViewCell() }
      
      let savedCert = stringCertificates[indexPath.row]
      cell.accessoryType = savedCert.isSelected ? .checkmark : .none
      if let cert = savedCert.cert {
        cell.setCertificate(cert: cert)
      }
      return cell
    }
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 1 {
      deselectAllCertificates()
      stringCertificates[indexPath.row].isSelected = true
      tableView.reloadData()
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier {
    case showTicketAcceptController:
      guard let ticketingController = segue.destination as? TicketingAcceptanceController,
        let acceptance = ticketingAcceptance, let selectedCertificate = selectedStringCertificate?.cert else { return }
      ticketingController.prepareTicketing(with: acceptance, certificate: selectedCertificate)

    default:
        break
    }
  }
}
