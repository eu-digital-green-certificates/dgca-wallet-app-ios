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
    static let hcertCellIndentifier = "CertificateTVC"
  }
  
  @IBOutlet weak var tableView      : UITableView!
  @IBOutlet weak var nextButton     : UIButton!
  
  private var listOfCert            : [DatedCertString]?
  
  private var validationServiceInfo : ServerListResponse?
  private var accessTokenInfo       : AccessTokenResponse?
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupTableView()
  }
  
  @IBAction func nextButtonAction(_ sender: Any) {
    let vc = TicketCodeAcceptViewController()
    
    present(vc, animated: true, completion: { [weak self] in
      vc.setCertsWith((self?.validationServiceInfo)!, (self?.accessTokenInfo)!)
    })
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
    //    TODO: Make filtering by all predicates (dob, validFrom/To, fullName)
    //    .filter { $0.cert!.fullName == fullName}
    validationServiceInfo = validationInfo
    accessTokenInfo = accessTokenModel
    listOfCert = LocalData.sharedInstance.certStrings.reversed()
  }
  
  private func deselectAllCert() {
    for i in 0..<(listOfCert?.count ?? 0) {
      if listOfCert?[i].isSelected ?? false {
        listOfCert?[i].isSelected = false
      }
    }
  }
  
  public func getSelectedCert() -> DatedCertString? {
    listOfCert?.filter({ hcert in
      hcert.isSelected
    }).first
  }
}

extension CertificatesListVC: UITableViewDataSource, UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return listOfCert?.count ?? .zero
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let hCert = listOfCert?[indexPath.row]
    let base = tableView.dequeueReusableCell(withIdentifier: Constants.hcertCellIndentifier, for: indexPath)
    guard let cell = base as? CertificateTVC else {
      return base
    }
    if let hCert = hCert?.cert {
      if hCert.isSelected  {
        cell.accessoryType = .checkmark
      } else {
        cell.accessoryType = .none
      }
      cell.selectionStyle = .none
      cell.setCertificate(cert: hCert)
    }
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      deselectAllCert()
      listOfCert?[indexPath.row].isSelected = true
      tableView.reloadRows(at: [indexPath], with: .automatic)
  }
}
