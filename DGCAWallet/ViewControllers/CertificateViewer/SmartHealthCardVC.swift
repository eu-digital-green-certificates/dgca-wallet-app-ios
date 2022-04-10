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

public class SmartHealthCardVC: UIViewController {
	
	@IBOutlet weak var cardTitle: UILabel!
	
	@IBOutlet weak var holderNameLabel: UILabel!
	@IBOutlet weak var holderDobLabel: UILabel!
	@IBOutlet weak var issuerLabel: UILabel!
	@IBOutlet weak var firstDoseDateLabel: UILabel!
	@IBOutlet weak var secondDoseLabel: UILabel!
	@IBOutlet weak var smartCardView: UIView!
	
	public var payload: String!
	
	public override func viewDidLoad() {
		super.viewDidLoad()
		setupView()
	}
	
	private func setupView() {
		setupCardShadow()
	}
	
	private func setupCardShadow() {
		smartCardView.layer.shadowOpacity = 0.7
		smartCardView.layer.shadowOffset = CGSize(width: 3, height: 3)
		smartCardView.layer.shadowRadius = 15.0
		smartCardView.layer.shadowColor = UIColor.darkGray.cgColor
	}
	
	@IBAction func didPressDoneBtn(_ sender: UIButton) {
	}
	@IBAction func didPressSaveBtn(_ sender: UIButton) {
	}
	
}

