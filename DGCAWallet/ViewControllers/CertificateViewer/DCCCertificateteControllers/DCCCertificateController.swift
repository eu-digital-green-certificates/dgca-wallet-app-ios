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

class DCCCertificateController: UIViewController {
    @IBOutlet fileprivate weak var table: UITableView!
    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!

    var certificate: MultiTypeCertificate? {
        (parent as? CertPagesController)?.embeddingVC?.certificate
    }
    private var validityState: ValidityState?
    private var sectionBuilder: DCCSectionBuilder?

    override func viewDidLoad() {
        super.viewDidLoad()
        validateAndSetupInterface()
        table.contentInset = .init(top: 0, left: 0, bottom: 32, right: 0)
    }

    private func validateAndSetupInterface() {
        guard let hCert = certificate?.digitalCertificate as? HCert else { return }
      
        activityIndicator.startAnimating()
        let validator = DCCCertificateValidator(with: hCert)
        let state = validator.validateWalletCertificate()
        self.validityState = state
        let builder = DCCSectionBuilder(with: hCert, validity: state, for: .wallet)
        self.sectionBuilder = builder
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.table.reloadData()
        }
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
