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
    guard let selectedIndexPath = tableView.indexPathForSelectedRow else { return }
    let service = listOfServices![selectedIndexPath.row]
    
    guard let validationMethod = serverListInfo?.verificationMethod.first(where: {
      $0.controller == service.serviceEndpoint
    }) else { return }
    
    GatewayConnection.getAccessTokenFor(servicePath: validationMethod.id, publicKey: validationMethod.publicKeyJwk.x5c) { response in
        print(response)
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
    listOfServices = serverListInfo?.service
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
      cell.setService(serv: service)
    }
    return cell
  }
}
