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
//  CertTable.swift
//  DGCAWallet
//  
//  Created by Yannick Spreen on 4/30/21.
//  

import SwiftDGC
import UIKit

class CertTableVC: UIViewController {
  @IBOutlet weak var table: UITableView!

  var hCert: HCert! {
    (parent as? CertPagesVC)?.embeddingVC.hCert
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    table.dataSource = self
    table.contentInset = .init(top: 0, left: 0, bottom: 32, right: 0)
    table.reloadData()
  }
}

extension CertTableVC: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return hCert.info.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let base = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath)
    guard let cell = base as? InfoCell else {
      return base
    }
    cell.draw(hCert.info[indexPath.row])
    return cell
  }
}
