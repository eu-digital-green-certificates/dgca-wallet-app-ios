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
//  WalletCell.swift
//  DGCAWallet
//
//  Created by Yannick Spreen on 4/20/21.
//

import UIKit
import DGCVerificationCenter

class WalletCell: UITableViewCell {
	@IBOutlet fileprivate weak var typeLabel: UILabel!
	@IBOutlet fileprivate weak var nameLabel: UILabel!
	@IBOutlet fileprivate weak var dateLabel: UILabel!
	@IBOutlet fileprivate weak var revocationLabel: UILabel!
	
	func setupCell(_ certificate: MultiTypeCertificate) {
		typeLabel.text = certificate.certTypeString.localized
		nameLabel.text = certificate.fullName
		dateLabel.text = String(format: "Scanned %@".localized, certificate.scannedDate.localDateString)
		// guard let cert = dated.cert else { return }
        if certificate.isRevoked {
            revocationLabel.isHidden = false
            revocationLabel.text = "Revoked".localized
        } else {
            revocationLabel.isHidden = true
        }
	}
}
