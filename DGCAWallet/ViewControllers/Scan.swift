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
//  ViewController.swift
//  DGCAWallet
//
//  Created by Yannick Spreen on 4/8/21.
//
//  https://www.raywenderlich.com/12663654-vision-framework-tutorial-for-ios-scanning-barcodes
//

import UIKit
import SwiftDGC
import FloatingPanel

class ScanVC: SwiftDGC.ScanVC {
  override func viewDidLoad() {
    super.viewDidLoad()

      applicationType = .wallet
      createDismissButton()
  }
    
   func createDismissButton() {
      let button = UIButton(frame: .zero)
      button.translatesAutoresizingMaskIntoConstraints = false
      button.backgroundColor = .clear
      button.setAttributedTitle(
        NSAttributedString(
          string: l10n("btn.cancel"),
          attributes: [
            .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
            .foregroundColor: UIColor.white
          ]
        ), for: .normal
      )
      button.addTarget(self, action: #selector(dismissScaner), for: .touchUpInside)
      view.addSubview(button)
       
      NSLayoutConstraint.activate([
        button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16.0),
        button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16.0)
      ])
    }
    
    @objc func dismissScaner() {
        self.dismiss(animated: true, completion: nil)
    }
}
