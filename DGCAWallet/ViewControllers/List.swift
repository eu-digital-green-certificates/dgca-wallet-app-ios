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
//  Home.swift
//  PatientScannerDemo
//  
//  Created by Yannick Spreen on 4/25/21.
//  
        

import Foundation
import UIKit
import SwiftDGC
import FloatingPanel

class ListVC: UIViewController {
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    return
  }

  @IBAction
  func scanNewCert() {
    performSegue(withIdentifier: "scanner", sender: self)
  }

  var presentingViewer: CertificateViewerVC?

  func presentViewer(for certificate: HCert) {
    guard
      presentingViewer == nil,
      let contentVC = UIStoryboard(name: "CertificateViewer", bundle: nil)
        .instantiateInitialViewController(),
      let viewer = contentVC as? CertificateViewerVC
    else {
      return
    }

    let fpc = FloatingPanelController()
    fpc.set(contentViewController: viewer)
    fpc.isRemovalInteractionEnabled = true // Let it removable by a swipe-down
    fpc.layout = FullFloatingPanelLayout()
    fpc.surfaceView.layer.cornerRadius = 24.0
    fpc.surfaceView.clipsToBounds = true
    viewer.hCert = certificate
    viewer.childDismissedDelegate = self
    presentingViewer = viewer

    present(fpc, animated: true, completion: nil)
  }
}

extension ListVC: CertViewerDelegate {
  func childDismissed() {
    presentingViewer = nil
  }
}
