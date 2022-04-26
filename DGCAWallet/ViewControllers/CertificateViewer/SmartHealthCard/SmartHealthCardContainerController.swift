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
//  SmartHealthCardVC.swift
//  DGCAWallet
//  
//  Created by Paul Ballmann on 08.04.22.
//  
        

import UIKit
import DGCVerificationCenter
import DGCSHInspection
import DGCCoreLibrary

public class CardContainerController: UIViewController {
	@IBOutlet weak var smartCardView: UIView!
	
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var cardSubtitleLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    
    public var certificate: MultiTypeCertificate?
    public var shCert: SHCert!
    public var editMode: Bool = false
    
    weak var delegate: CertificateManaging?
        
	public override func viewDidLoad() {
		super.viewDidLoad()
        setupView()
        guard let shCert = certificate?.digitalCertificate as? SHCert else { return }
        self.shCert = shCert
	}
	
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? CardPageController, segue.identifier == "pageEmbedSegue" {
            guard let shCert = certificate?.digitalCertificate as? SHCert else { return }
            vc.shCert = shCert
            vc.editMode = self.editMode
            // vc.controllers = controllers
        }
    }
    
	private func setupView() {
        if editMode {
            self.saveButton.isHidden = true
        }
    }
	
	@IBAction func didPressDoneBtn(_ sender: UIButton) {
        self.dismiss(animated: true)
	}
	
	@IBAction func didPressSaveBtn(_ sender: UIButton) {
        SHDataCenter.shDataManager.add(shCert) { result in
            DispatchQueue.main.async {
                self.showAlert(title: "Smart Helth Card saved successfully".localized, subtitle: "Your card is now awailable in the Wallet App".localized) { _ in
                    self.dismiss(animated: true)
                    if let cert = try? MultiTypeCertificate(from: self.shCert.fullPayloadString) {
                        self.delegate?.certificateViewer(self, didAddCeCertificate: cert)
                    } else {
                        DGCLogger.logError("Cannot add SHC certificate")
                    }
                }
            }
        }
	}
}
