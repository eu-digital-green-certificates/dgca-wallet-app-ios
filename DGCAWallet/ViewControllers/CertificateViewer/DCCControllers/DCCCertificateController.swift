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
//  DCCCertificateController.swift
//  DGCAWallet
//
//  Created by Yannick Spreen on 4/30/21.
//

import UIKit
import DCCInspection
import DGCVerificationCenter
import DGCCoreLibrary

class DCCCertificateController: UIViewController {
    @IBOutlet fileprivate weak var table: UITableView!
    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!
    
    private var sectionBuilder: DCCSectionBuilder? {
        (parent as? CertPagesController)?.embeddingVC?.sectionBuilder
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        table.contentInset = .init(top: 0, left: 0, bottom: 32, right: 0)
        self.table.reloadData()
    }
}

extension DCCCertificateController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sectionBuilder?.infoSection.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath) as? InfoCell
        else {  return UITableViewCell() }
        
        if let infoSection = self.sectionBuilder?.infoSection[indexPath.row] {
            cell.setupCell(infoSection)
        }
        return cell
    }
}
