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
//  ServersListVC.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 21.09.2021.
//  

import UIKit
import SwiftDGC
import Security

class ServersListVC: UIViewController {
  
    private enum Constants {
      static let cellIndentifier = "ServerCell"
      static let showCertificatesList = "showCertificatesList"
    }

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var nextButton: UIButton!
  
  private var serverListInfo: ServerListResponse?
  private var listOfServices = [ValidationService]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    title = l10n("services")
  }
  
  override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        self.navigationController?.isNavigationBarHidden = (parent == nil)
  }

  @IBAction func nextButtonAction(_ sender: Any) {
    guard let service = getSelectedServer() else {
      let alertController: UIAlertController = {
          let controller = UIAlertController(title: l10n("please select one of service server"), message: "",
             preferredStyle: .alert)
        let actionOk = UIAlertAction(title: l10n("ok"), style: .default)
        controller.addAction(actionOk)
        return controller
      }()
      self.present(alertController, animated: true)
      return
    }
    
    guard let privateKey = Enclave.loadOrGenerateKey(with: "validationKey"),
        let publicKey = SecKeyCopyPublicKey(privateKey) else { return }
    
    var base64PublicKeyString = ""
    var error:Unmanaged<CFError>?
    
    if let cfdata = SecKeyCopyExternalRepresentation(publicKey, &error) {
      let data:Data = cfdata as Data
      base64PublicKeyString = data.base64EncodedString()
    }
    
    guard let accessTokenService = serverListInfo?.service?.first(where: { $0.type == "AccessTokenService" }),
      let url = URL(string: accessTokenService.serviceEndpoint),
        let serviceURL = URL(string: service.serviceEndpoint) else { return }
    
    GatewayConnection.getServiceInfo(url: serviceURL) { [weak self] validationServiceInfo in
//      TODO: Show UI message with error if fail to fetch serviceInfo
      guard let serviceInfo = validationServiceInfo else { return }
      
      GatewayConnection.getAccessTokenFor(url: url, servicePath: service.id,
        publicKey: base64PublicKeyString) { response in
        guard let accessTokenResponse = response else { return }
        DispatchQueue.main.async {
            self?.performSegue(withIdentifier: Constants.showCertificatesList,
                sender: (serviceInfo, accessTokenResponse))
        }
      }
    }
  }
  
  public func setServices(info: ServerListResponse) {
    serverListInfo = info
      listOfServices = serverListInfo?.service?.filter{ $0.type == "ValidationService" } ?? []
  }
  
  private func deselectAllServers() {
    for i in 0..<listOfServices.count {
        listOfServices[i].isSelected = false
    }
  }
  
  private func getSelectedServer() -> ValidationService? {
      listOfServices.filter({ $0.isSelected ?? false }).first
  }
    
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier {
    case Constants.showCertificatesList:
        guard let certController = segue.destination as? CertificatesListVC,
            let (serviceInfo,tokenResponse) = sender as? (ServerListResponse, AccessTokenResponse) else { return }
        certController.setCertsWith(serviceInfo, tokenResponse)
    default:
        break
    }
  }
}

extension ServersListVC: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return listOfServices.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIndentifier,
        for: indexPath) as? ServerCell else { return UITableViewCell() }
      
    let service = listOfServices[indexPath.row]
    cell.accessoryType = (service.isSelected ?? false) ? .checkmark : .none
    cell.setService(serv: service)
      
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      deselectAllServers()
      listOfServices[indexPath.row].isSelected = true
      tableView.reloadData()
  }
}
