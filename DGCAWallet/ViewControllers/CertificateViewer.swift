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
  @IBOutlet weak var headerBackground: UIView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var dismissButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var cancelButtonConstraint: NSLayoutConstraint!

  var hCert: HCert!
  var childDismissedDelegate: CertViewerDelegate?
  public var isSaved = true

  func draw() {
    nameLabel.text = hCert.fullName
    if !isSaved {
      dismissButton.setTitle("Save", for: .normal)
    }
    headerBackground.backgroundColor = isSaved ? .blue : .grey10
    nameLabel.textColor = isSaved ? .white : .black
    cancelButton.alpha = isSaved ? 0 : 1
    cancelButtonConstraint.priority = .init(isSaved ? 997 : 999)
    view.layoutIfNeeded()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    draw()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    return
  }

  var newCertAdded = false
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    Brightness.reset()
    childDismissedDelegate?.childDismissed(newCertAdded)
  }

  @IBAction
  func closeButtonClick() {
    if isSaved {
      return dismiss(animated: true, completion: nil)
    }
    saveCert()
  }

  @IBAction
  func cancelButtonClick() {
    dismiss(animated: true, completion: nil)
  }

  func saveCert() {
    showInputDialog(
      title: "Confirm TAN",
      subtitle: "Please enter the TAN that was provided together with your certificate:",
      inputPlaceholder: "XYZ12345"
    ) { [weak self] in
      guard let cert = self?.hCert else {
        return
      }
      GatewayConnection.claim(cert: cert, with: $0) {
        if $0 {
          guard let cert = self?.hCert else {
            return
          }
          LocalData.add(cert)
          self?.newCertAdded = true
          self?.showAlert(
            title: "Success",
            subtitle: "Certificate was saved to wallet!"
          ) { _ in
            self?.dismiss(animated: true, completion: nil)
          }
        } else {
          self?.showAlert(
            title: "Failure",
            subtitle: "Check the TAN and try again."
          )
        }
      }
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let child = segue.destination as? CertPagesVC {
      child.embeddingVC = self
    }
  }
}
