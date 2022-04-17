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
//  CardController.swift
//  DGCAWallet
//  
//  Created by Paul Ballmann on 13.04.22.
//  
        

import UIKit
import DGCSHInspection

class CardController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dobLabel: UILabel!
    @IBOutlet weak var issuerLabel: UILabel!
    @IBOutlet weak var lastDoseLabel: UILabel!
    @IBOutlet weak var doseCountLabel: UILabel!
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var cardView: UIView!
    
    public var shCert: SHCert!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCardShadow()
        loadData()
    }
    
    private func loadData() {
        switch shCert.type {
            case .immunization:
                self.titleLabel.text = "Vaccination Card"
                self.subtitleLabel.text = "COVID-19"
                break
            case .other:
            self.titleLabel.text = "Smart Health Card"
            self.subtitleLabel.isHidden = true
                break
        }
        subtitleLabel.text = shCert.subType.uppercased()
        nameLabel.text = shCert.fullName
        dobLabel.text = shCert.dateOfBirth
        issuerLabel.text = shCert.issuer
        lastDoseLabel.text = shCert.dates.last!.string!
    }
    
    private func setupCardShadow() {
        cardView.layer.shadowOpacity = 0.7
        cardView.layer.shadowOffset = CGSize(width: 3, height: 3)
        cardView.layer.shadowRadius = 15.0
        cardView.layer.shadowColor = UIColor.darkGray.cgColor
    }
    
    
}
