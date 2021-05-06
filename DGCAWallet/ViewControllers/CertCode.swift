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

class CertCodeVC: UIViewController {
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var tanLabel: UILabel!

  var hCert: HCert! { (parent as? CertPagesVC)?.embeddingVC.hCert }
  var tan: String? { (parent as? CertPagesVC)?.embeddingVC.tan }

  override func viewDidLoad() {
    super.viewDidLoad()

    imageView.image = hCert.qrCode
    tanLabel.text = ""
    if let tan = tan {
      tanLabel.text = "TAN: \(tan)"
    }
  }
}
