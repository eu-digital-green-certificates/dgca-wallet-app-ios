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
//  CertificateViewer.swift
//  DGCAWallet
//
//  Created by Yannick Spreen on 4/19/21.
//

import Foundation
import UIKit
import FloatingPanel
import SwiftDGC

class CertificateViewerVC: UIViewController {
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var typeSegments: UISegmentedControl!
  @IBOutlet weak var dismissButton: UIButton!

  var hCert: HCert!

  var childDismissedDelegate: CertViewerDelegate?

  func draw() {
    nameLabel.text = hCert.fullName
    typeSegments.selectedSegmentIndex = [
      HCertType.test,
      HCertType.vaccine,
      HCertType.recovery
    ].firstIndex(of: hCert.type) ?? 0
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // selected option color
    typeSegments.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black!], for: .selected)
    // color of other options
    typeSegments.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.disabledText!], for: .normal)
    typeSegments.backgroundColor = UIColor(white: 1.0, alpha: 0.06)
    draw()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    return
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    childDismissedDelegate?.childDismissed()
  }

  @IBAction
  func closeButton() {
    dismiss(animated: true, completion: nil)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let child = segue.destination as? CertPagesVC {
      child.embeddingVC = self
    }
  }
}
