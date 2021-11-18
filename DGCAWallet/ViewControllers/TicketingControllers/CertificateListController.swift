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
    static let showTicketAcceptController = "showTicketAcceptController"
  }
  
  @IBOutlet fileprivate weak var tableView: UITableView!
  @IBOutlet fileprivate weak var nextButton: UIButton!
  
  var ticketingAcceptance: TicketingAcceptance? {
    didSet {
      self.reloadComponents()
    }
  }
  
  private var stringCertificates = [DatedCertString]()
  private var selectedStringCertificate: DatedCertString? {
    return stringCertificates.filter({ $0.isSelected }).first
  }

  private var accessTokenInfoKeys = ["Name", "Date of birth", "Departure", "Arrival", "Accepted certificate type", "Category", "Validation Time", "Valid from","Valid to"]
  private var accessTokenInfoValues = [String]()
  
  private var isNavigationEnabled: Bool {
    return ticketingAcceptance != nil && selectedStringCertificate?.cert != nil
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    guard let vcValue = ticketingAcceptance?.accessInfo.vc else { return }
    
    accessTokenInfoValues = ["\(vcValue.gnt!) \(vcValue.fnt!)", vcValue.dob!, "\(vcValue.cod!),\(vcValue.rod!)", "\(vcValue.coa!),\(vcValue.roa!)", vcValue.type!.joined(separator: ","), vcValue.category!.joined(separator: ","), vcValue.validationClock!, vcValue.validFrom!, vcValue.validTo!]
    
    tableView.tableFooterView = UIView()
    title = l10n("Certificates")
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    tableView.reloadData()
  }
  
  @IBAction func nextButtonAction(_ sender: Any) {
    guard let _ = selectedStringCertificate?.cert else {
      self.showInfoAlert(withTitle: l10n("Please select a certificate"), message: l10n("Here are all the appropriate certificates."))
        return
    }
    
    self.performSegue(withIdentifier: Constants.showTicketAcceptController, sender: nil)
  }
  
  func reloadComponents() {
    guard let validationCertificate = ticketingAcceptance?.accessInfo.vc,
      let givenName = validationCertificate.gnt, let familyName = validationCertificate.fnt else { return }
    
    let array = DataCenter.certStrings.filter { ($0.cert!.fullName.lowercased() == "\(givenName) \(familyName)".lowercased()) &&
      ($0.cert!.dateOfBirth == validationCertificate.dob) }
    stringCertificates = array
    
    let validDateFrom = validationCertificate.validFrom ?? ""
    if let dateValidFrom = Date(rfc3339DateTimeString: validDateFrom) {
      let array = stringCertificates.filter{ $0.cert!.iat < dateValidFrom }
      stringCertificates = array
    }
    
    let validDateTo = validationCertificate.validTo ?? ""
    if let dateValidUntil = Date(rfc3339DateTimeString: validDateTo) {
      let array = stringCertificates.filter {$0.cert!.exp > dateValidUntil }
      stringCertificates = array
    }
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
      switch ticketingAcceptance?.accessInfo.t {
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
      return nil
    } else {
      return l10n("Certificates")
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      let cellID = String(describing: TokenInfoCell.self)
      guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? TokenInfoCell
      else { return UITableViewCell() }
      
      cell.fieldName.text = accessTokenInfoKeys[indexPath.row]
      cell.fieldValue.text = accessTokenInfoValues[indexPath.row]
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
  
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let savedCert = stringCertificates[indexPath.row]
      showAlert(title: l10n("cert.delete.title"), subtitle: l10n("cert.delete.body"), actionTitle: l10n("btn.confirm"),
       cancelTitle: l10n("btn.cancel")) {
          if $0 {
           DataCenter.localDataManager.remove(withDate: savedCert.date) { [weak self] _ in
             self?.reloadComponents()
             DispatchQueue.main.asyncAfter(deadline: .now()) {
               self?.tableView.reloadData()
             }
           }
         }
       }
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
    case Constants.showTicketAcceptController:
      guard let ticketingController = segue.destination as? TicketingAcceptanceController,
          let acceptance = ticketingAcceptance,
          let selectedCertificate = selectedStringCertificate?.cert else { return }
      
      ticketingController.prepareTicketing(with: acceptance, certificate: selectedCertificate)

    default:
        break
    }
  }
}
