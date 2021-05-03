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

    if let cert = newHCertScanned {
      newHCertScanned = nil
      presentViewer(for: cert)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    table.dataSource = self
    table.delegate = self
    reloadTable()
  }

  @IBAction
  func scanNewCert() {
    performSegue(withIdentifier: "scanner", sender: self)
  }

  @IBOutlet weak var table: UITableView!

  func reloadTable() {
    table.reloadData()
  }

  var presentingViewer: CertificateViewerVC?
  var newHCertScanned: HCert?

  func presentViewer(for certificate: HCert) {
    guard
      presentingViewer == nil,
      let contentVC = UIStoryboard(name: "CertificateViewer", bundle: nil)
        .instantiateInitialViewController(),
      let viewer = contentVC as? CertificateViewerVC
    else {
      return
    }

    viewer.hCert = certificate
    viewer.childDismissedDelegate = self
    let fpc = FloatingPanelController()
    fpc.set(contentViewController: viewer)
    fpc.isRemovalInteractionEnabled = true // Let it removable by a swipe-down
    fpc.layout = FullFloatingPanelLayout()
    fpc.surfaceView.layer.cornerRadius = 24.0
    fpc.surfaceView.clipsToBounds = true
    fpc.delegate = self
    presentingViewer = viewer

    present(fpc, animated: true, completion: nil)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    super.prepare(for: segue, sender: sender)

    if let scan = segue.destination as? ScanVC {
      scan.delegate = self
      return
    }
  }
}

extension ListVC: CertViewerDelegate {
  func childDismissed() {
    presentingViewer = nil
  }
}

extension ListVC: ScanVCDelegate {
  func hCertScanned(_ cert: HCert) {
    LocalData.add(cert)
    newHCertScanned = cert
    DispatchQueue.main.async { [weak self] in
      self?.reloadTable()
      self?.navigationController?.popViewController(animated: true)
    }
  }
}

extension ListVC: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    LocalData.sharedInstance.certStrings.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = table.dequeueReusableCell(withIdentifier: "walletCell", for: indexPath)
    guard let walletCell = cell as? WalletCell else {
      return cell
    }

    walletCell.draw(LocalData.sharedInstance.certStrings[indexPath.row])
    return walletCell
  }
}

extension ListVC: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    table.deselectRow(at: indexPath, animated: true)
    guard
      let cert = LocalData.sharedInstance.certStrings[indexPath.row].cert
    else {
      return
    }
    presentViewer(for: cert)
  }
}

extension ListVC: FloatingPanelControllerDelegate {
  func floatingPanel(_ fpc: FloatingPanelController, shouldRemoveAt location: CGPoint, with velocity: CGVector) -> Bool {
    let pos = location.y / view.bounds.height
    if pos >= 0.33 {
      return true
    }
    let threshold: CGFloat = 5.0
    switch fpc.layout.position {
    case .top:
        return (velocity.dy <= -threshold)
    case .left:
        return (velocity.dx <= -threshold)
    case .bottom:
        return (velocity.dy >= threshold)
    case .right:
        return (velocity.dx >= threshold)
    }
  }
}
