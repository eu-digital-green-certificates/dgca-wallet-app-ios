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
//  DCCCertCodeController.swift
//  DGCAWallet
//  
//  Created by Yannick Spreen on 4/30/21.
//  

import UIKit
import DCCInspection
import DGCVerificationCenter

class DCCCertCodeController: UIViewController {
    @IBOutlet fileprivate weak var imageView: UIImageView!
    @IBOutlet fileprivate weak var tanLabel: UILabel!

    var certificate: MultiTypeCertificate? {
        (parent as? CertPagesController)?.embeddingVC?.certificate
    }
    
    var tan: String? {
        (parent as? CertPagesController)?.embeddingVC?.tan
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let hCert = certificate?.digitalCertificate as? HCert else { return }

        imageView.image = hCert.qrCode
        tanLabel.text = ""
        if tan != nil {
			tanLabel.text = String(format: "TAN: %@".localized, "tap to reveal".localized)
			tanLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapToReveal)))
			tanLabel.isUserInteractionEnabled = true
        }
    }

    @IBAction func tapToReveal() {
        if let tan = tan {
            tanLabel.text = String(format: "TAN: %@".localized, tan)
        }
    }
}
