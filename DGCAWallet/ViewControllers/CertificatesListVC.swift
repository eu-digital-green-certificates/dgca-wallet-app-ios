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
  
  private func setupView() {
    tableView.reloadData()
  }
  
  private func setupTableView() {
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(UINib(nibName: Constants.hcertCellIndentifier, bundle: nil),
                       forCellReuseIdentifier: Constants.hcertCellIndentifier)
    tableView.reloadData()
  }

  public func setCertsWith(_ validationInfo: ServerListResponse,_ accessTokenModel : AccessTokenResponse) {
    // TODO: Make filtering by all predicates (dob, validFrom/To, fullName)
        
    validationServiceInfo = validationInfo
    accessTokenInfo = accessTokenModel
    
//    || ($0.cert!.certTypeString == accessTokenModel.vc?.type?.first)
    
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
      let hCert = listOfCert[indexPath.row]

      cell.accessoryType = hCert.isSelected ? .checkmark : .none
      if let cert = hCert.cert {
          cell.setCertificate(cert: cert)
      }
      return cell
  }
    
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      deselectAllCert()
      listOfCert[indexPath.row].isSelected = true
      tableView.reloadRows(at: [indexPath], with: .automatic)
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 90.0
  }
}
