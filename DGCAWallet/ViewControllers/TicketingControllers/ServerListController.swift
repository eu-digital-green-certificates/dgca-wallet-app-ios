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
//  ServerListController.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 21.09.2021.
//  

import UIKit
import SwiftDGC

class ServerListController: UIViewController {
  private enum Segues {
    static let showCertificatesList = "showCertificatesList"
  }

  @IBOutlet fileprivate weak var tableView: UITableView!
  @IBOutlet fileprivate weak var nextButton: UIButton!
  
  weak var dismissDelegate: DismissControllerDelegate?
  
  var serverListInfo: ServerListResponse? {
    didSet {
      listOfServices = serverListInfo?.service?.filter{ $0.type == "ValidationService" } ?? []
    }
  }
  
  private var listOfServices = [ValidationService]()

  private var selectedServer: ValidationService? {
    return listOfServices.filter({ $0.isSelected ?? false }).first
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Services".localized
    nextButton.setTitle("Next".localized, for: .normal)
    self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    tableView.reloadData()
  }
    
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    dismissDelegate?.userDidDissmiss(self)
  }

  override func willMove(toParent parent: UIViewController?) {
    super.willMove(toParent: parent)
    self.navigationController?.isNavigationBarHidden = (parent == nil)
  }

  @IBAction func nextButtonAction(_ sender: Any) {
    guard let service = selectedServer else {
      showNotSelectedServise()
      return
    }
    guard let privateKey = Enclave.loadOrGenerateKey(with: "validationKey") else {
      showAlertInternalError()
      return
    }
    guard let accessTokenService = serverListInfo?.service?.first(where: { $0.type == "AccessTokenService" }),
      let url = URL(string: accessTokenService.serviceEndpoint), let serviceURL = URL(string: service.serviceEndpoint) else {
        showAlertInternalError()
        return
    }
    IdentityService.getServiceInfo(url: serviceURL) { [weak self] info, error in
      guard error == nil, let serviceInfo = info else {
        self?.showAlertServiceCannotUse()
        return
      }
      
      let pubKey = (X509.derPubKey(for: privateKey) ?? Data()).base64EncodedString()
      
      GatewayConnection.loadAccessToken(url, servicePath: service.id, publicKey: pubKey) { response, error in
        DispatchQueue.main.async { [weak self] in
          guard let response = response else {
            self?.showNetworkingError()
            return
          }
          let ticketingAcceptance = TicketingAcceptance(validationInfo: serviceInfo, accessInfo: response)
          self?.performSegue(withIdentifier: Segues.showCertificatesList, sender: ticketingAcceptance)
        }
      }
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier {
    case Segues.showCertificatesList:
        guard let certificateListController = segue.destination as? CertificateListController,
          let acceptance = sender as? TicketingAcceptance else { return }
        certificateListController.ticketingAcceptance = acceptance
    default:
        break
    }
  }
}

extension ServerListController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return listOfServices.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cellID = String(describing: ServerCell.self)
    guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? ServerCell
    else { return UITableViewCell() }
    
    let service = listOfServices[indexPath.row]
    cell.accessoryType = (service.isSelected ?? false) ? .checkmark : .none
    cell.setService(serv: service)
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    for i in 0..<listOfServices.count {
        listOfServices[i].isSelected = false
    }
    listOfServices[indexPath.row].isSelected = true
    tableView.reloadData()
  }
}

//Alerts
extension ServerListController {
  func showNotSelectedServise() {
    DispatchQueue.main.async {
      self.showInfoAlert(withTitle: "Please select the required service".localized,
          message: "Each service is located on a separate server and is designed for specific activities.".localized)
    }
  }

  func showAlertServiceCannotUse() {
    DispatchQueue.main.async {
      self.showInfoAlert(withTitle: "The specified service cannot be used".localized,
          message: "Make sure you select the desired service...".localized)
    }
  }
  
  func showAlertInternalError() {
    DispatchQueue.main.async {
      self.showInfoAlert(withTitle: "An internal error has occurred".localized,
          message: "Please quit the application and restart again.".localized)
    }
  }
  
  func showNetworkingError() {
    DispatchQueue.main.async {
      self.showInfoAlert(withTitle: "An internet connection error has occurred".localized,
          message: "Make sure your device is connected to the internet and try again...".localized)
    }
  }
}
