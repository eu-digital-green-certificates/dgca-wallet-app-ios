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
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var nextButton: UIButton!
  
  private enum Constants {
    static let cellIndentifier = "ServerTVC"
  }
  
  private var serverListInfo : ServerListResponse?
  private var listOfServices: [ValidationService]?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupTableView()
  }
  
  @IBAction func nextButtonAction(_ sender: Any) {
    guard let service = getSelectedServer() else {
      let alertController: UIAlertController = {
          let controller = UIAlertController(title: "please select one of service server",
                                             message: "",
                                             preferredStyle: .alert)
        let actionOk = UIAlertAction(title: l10n("ok"), style: .default)
        controller.addAction(actionOk)
          return controller
      }()
      self.present(alertController, animated: true)
      return
    }
    
    guard let privateKey = Enclave.loadOrGenerateKey(with: "validationKey") else { return }
    
    let accessTokenService = serverListInfo?.service?.first(where: {
      $0.type == "AccessTokenService"
    })
    
    let url = URL(string: accessTokenService!.serviceEndpoint)!
    guard let serviceURL = URL(string: service.serviceEndpoint) else { return }
    
    IdentityService.getServiceInfo(url: serviceURL) { [weak self] validationServiceInfo in
      
//      TODO: Show UI message with error if fail to fetch serviceInfo
      
      guard let serviceInfo = validationServiceInfo else { return }
      
      let pubKey = (X509.derPubKey(for: privateKey) ?? Data()).base64EncodedString()
      
      GatewayConnection.getAccessTokenFor(url: url,servicePath: service.id, publicKey: pubKey) { response in
        DispatchQueue.main.async { [weak self] in
          let vc = CertificatesListVC()
          
          guard let accessTokenResponse = response else { return }
          vc.setCertsWith(serviceInfo, accessTokenResponse)
          self?.navigationController?.pushViewController(vc, animated: true)
        }
      }
    }
    
  }
  
  private func setupView() {
    tableView.reloadData()
  }
  
  private func setupTableView() {
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(UINib(nibName: Constants.cellIndentifier, bundle: nil),
                       forCellReuseIdentifier: Constants.cellIndentifier)
    tableView.reloadData()
  }
  
  public func setServices(info: ServerListResponse) {
    serverListInfo = info
    listOfServices = serverListInfo?.service?.filter{
      $0.type == "ValidationService"
    }
  }
  
  private func deselectAllServers() {
    for i in 0..<(listOfServices?.count ?? 0) {
      if listOfServices?[i].isSelected ?? false {
        listOfServices?[i].isSelected = false
      }
    }
  }
  
  private func getSelectedServer() -> ValidationService? {
    listOfServices?.filter({ serv in
      serv.isSelected ?? false
    }).first
  }
}

extension ServersListVC: UITableViewDataSource, UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return listOfServices?.count ?? .zero
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let service = listOfServices?[indexPath.row]
    let base = tableView.dequeueReusableCell(withIdentifier: Constants.cellIndentifier, for: indexPath)
    guard let cell = base as? ServerTVC else {
      return base
    }
    if let service = service {
      if let selected = service.isSelected, selected  {
        cell.accessoryType = .checkmark
      } else {
        cell.accessoryType = .none
      }
      cell.selectionStyle = .none
      cell.setService(serv: service)
    }
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      deselectAllServers()
      listOfServices?[indexPath.row].isSelected = true
      tableView.reloadData()
  }
}
