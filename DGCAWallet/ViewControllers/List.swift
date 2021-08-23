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
//  DGCAWallet
//  
//  Created by Yannick Spreen on 4/25/21.
//  

import Foundation
import UIKit
import SwiftDGC
import FloatingPanel
import SwiftCBOR
import CoreImage
import PDFKit
import UniformTypeIdentifiers
import MobileCoreServices
import CoreServices

class ListVC: UIViewController {
  
  @IBOutlet weak var addButton: RoundedButton!
  
  var picker = UIImagePickerController()
  var alert: UIAlertController?
  var viewController: UIViewController?
  var pickImageCallback : ((UIImage) -> Void)?

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    if let cert = newHCertScanned {
      newHCertScanned = nil
      presentViewer(for: cert, isSaved: false)
    }
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    table.dataSource = self
    table.delegate = self
    reloadTable()
  }

  @IBAction
  func addNew() {
    let menuActionSheet =  UIAlertController(title: "Add new?",
                                             message: "Did you want to add new certificate, image or PDF file?",
                                             preferredStyle: UIAlertController.Style.actionSheet)
    menuActionSheet.addAction(UIAlertAction(title: "Scan certificate",
                                            style: UIAlertAction.Style.default,
                                            handler: {[weak self] _ in
      self?.scanNewCertificate()
    }))
    menuActionSheet.addAction(UIAlertAction(title: "Export certificate from image or export image",
                                            style: UIAlertAction.Style.default,
                                            handler: { [weak self] _ in
      self?.addImage()
     }))
    menuActionSheet.addAction(UIAlertAction(title: "PDF file export",
                                            style: UIAlertAction.Style.default,
                                            handler: { [weak self] _ in
      self?.addPdf()
     }))
    menuActionSheet.addAction(UIAlertAction(title: "NFC Export",
                                            style: UIAlertAction.Style.default,
                                            handler: { [weak self] _ in
      self?.scanNFC()
     }))
    
    menuActionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: UIAlertAction.Style.destructive,
                                            handler: nil))
    present(menuActionSheet, animated: true, completion: nil)
  }
  
  private func scanNewCertificate() {
    performSegue(withIdentifier: "scanner", sender: self)
  }

  private func addImage() {
    getImageFrom()
  }

  private func addPdf() {
    let pdfPicker: UIDocumentPickerViewController?
    if #available(iOS 14.0, *) {
      let supportedTypes: [UTType] = [UTType.pdf]
      pdfPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
    } else {
      pdfPicker = UIDocumentPickerViewController(documentTypes: [kUTTypePDF as String], in: .open)
    }
    pdfPicker?.delegate = self
    guard let pdfPicker = pdfPicker else {
      return
    }
    present(pdfPicker, animated: true, completion: nil)
  }

  private func scanNFC() {
    let helper = NFCHelper()
    helper.onNFCResult = onNFCResult(success:msg:)
    helper.restartSession()
  }

  func onNFCResult(success: Bool, msg: String) {
    DispatchQueue.main.async { [weak self] in
      print("\(msg)")
      if success, let hCert = HCert(from: msg, applicationType: .wallet) {
        self?.saveQrCode(cert: hCert)
      } else {
        let alertController: UIAlertController = {
            let controller = UIAlertController(title: "Error",
                                               message: "Reading DCC from NFC",
                                               preferredStyle: .alert)
          let actionRetry = UIAlertAction(title: "Retry", style: .default) { _ in
            self?.scanNFC()
          }
            controller.addAction(actionRetry)
          let actionOk = UIAlertAction(title: "OK", style: .default)
          controller.addAction(actionOk)
            return controller
        }()
        self?.viewController?.present(alertController, animated: true)
      }
    }
  }
  
  @IBAction func settingsTapped(_ sender: UIButton) {
    guard let settingsVC = UIStoryboard(name: "Settings", bundle: nil).instantiateInitialViewController(),
          let viewer = settingsVC as? SettingsVC else {
      return
    }
    viewer.childDismissedDelegate = self
    showFloatingPanel(for: viewer)
  }

  func showFloatingPanel(for controller: UIViewController) {
    let fpc = FloatingPanelController()
    fpc.set(contentViewController: controller)
    fpc.isRemovalInteractionEnabled = true
    fpc.layout = FullFloatingPanelLayout()
    fpc.surfaceView.layer.cornerRadius = 24.0
    fpc.surfaceView.clipsToBounds = true
    fpc.delegate = self
    presentingViewer = controller

    present(fpc, animated: true, completion: nil)
  }

  @IBOutlet weak var table: UITableView!
  @IBOutlet weak var emptyView: UIView!

  func reloadTable() {
    emptyView.alpha = listElements.isEmpty ? 1 : 0
    table.reloadData()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    presentingViewer?.dismiss(animated: true, completion: nil)
  }

  var presentingViewer: UIViewController?
  var newHCertScanned: HCert?

  func presentViewer(for certificate: HCert, with tan: String? = nil, isSaved: Bool = true) {
    guard
      presentingViewer == nil,
      let contentVC = UIStoryboard(name: "CertificateViewer", bundle: nil)
        .instantiateInitialViewController(),
      let viewer = contentVC as? CertificateViewerVC
    else {
      return
    }

    viewer.isSaved = isSaved
    viewer.hCert = certificate
    viewer.tan = tan
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
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
  func childDismissed(_ newCertAdded: Bool) {
    if newCertAdded {
      reloadTable()
    }
    presentingViewer = nil
  }
}

extension ListVC: ScanVCDelegate {
  func disableBackgroundDetection() {
    SecureBackground.paused = true
  }

  func enableBackgroundDetection() {
    SecureBackground.paused = false
  }

  func hCertScanned(_ cert: HCert) {
    newHCertScanned = cert
    DispatchQueue.main.async { [weak self] in
      self?.navigationController?.popViewController(animated: true)
    }
  }
}

extension ListVC: UITableViewDataSource {
  var listElements: [DatedCertString] {
    LocalData.sharedInstance.certStrings.reversed()
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    listElements.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = table.dequeueReusableCell(withIdentifier: "walletCell", for: indexPath)
    guard let walletCell = cell as? WalletCell else {
      return cell
    }

    walletCell.draw(listElements[indexPath.row])
    return walletCell
  }
}

extension ListVC: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    table.deselectRow(at: indexPath, animated: true)
    guard
      let cert = listElements[indexPath.row].cert
    else {
      return
    }
    presentViewer(for: cert, with: listElements[indexPath.row].storedTAN)
  }

  func tableView(
    _ tableView: UITableView,
    commit editingStyle: UITableViewCell.EditingStyle,
    forRowAt indexPath: IndexPath
  ) {
    let cert = listElements[indexPath.row]
    showAlert(
      title: l10n("cert.delete.title"),
      subtitle: l10n("cert.delete.body"),
      actionTitle: l10n("btn.confirm"),
      cancelTitle: l10n("btn.cancel")
    ) { [weak self] in
      if $0 {
        LocalData.sharedInstance.certStrings.removeAll {
          $0.date == cert.date
        }
        LocalData.sharedInstance.save()
        self?.reloadTable()
      }
    }
  }
}

extension ListVC: FloatingPanelControllerDelegate {
  func floatingPanel(
    _ fpc: FloatingPanelController,
    shouldRemoveAt location: CGPoint,
    with velocity: CGVector
  ) -> Bool {
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

extension ListVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  private func getImageFrom() {
    alert = UIAlertController(title: "Get Image From", message: nil, preferredStyle: .actionSheet)
    let cameraAction = UIAlertAction(title: "Camera", style: .default) {[weak self] _ in
      self?.openCamera()
    }
    let galleryAction = UIAlertAction(title: "Gallery", style: .default) {[weak self] _ in
      self?.openGallery()
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
    
    // Add the actions
    picker.delegate = self
    alert?.addAction(cameraAction)
    alert?.addAction(galleryAction)
    alert?.addAction(cancelAction)
    guard let alert = alert else { return }
    present(alert, animated: true, completion: nil)
  }

  func pickImage(_ viewController: UIViewController, _ callback: @escaping ((UIImage) -> Void)) {
      pickImageCallback = callback
      self.viewController = viewController
//      alert.popoverPresentationController?.sourceView = self.viewController!.view
  }
  func openCamera() {
      alert?.dismiss(animated: true, completion: nil)
      if(UIImagePickerController.isSourceTypeAvailable(.camera)) {
          picker.sourceType = .camera
          present(picker, animated: true, completion: nil)
      } else {
          let alertController: UIAlertController = {
              let controller = UIAlertController(title: "Warning",
                                                 message: "You don't have camera",
                                                 preferredStyle: .alert)
              let action = UIAlertAction(title: "OK", style: .default)
              controller.addAction(action)
              return controller
          }()
          viewController?.present(alertController, animated: true)
      }
  }
  func openGallery() {
      alert?.dismiss(animated: true, completion: nil)
      picker.sourceType = .photoLibrary
      present(picker, animated: true, completion: nil)
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      picker.dismiss(animated: true, completion: nil)
  }

  func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    picker.dismiss(animated: true, completion: nil)
    guard let image = info[.originalImage] as? UIImage else {
      fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
    }
    tryFoundQRCodeIn(image: image)
  }

  @objc func imagePickerController(_ picker: UIImagePickerController, pickedImage: UIImage?) {
    guard let pickedImage = pickedImage else { return }
    tryFoundQRCodeIn(image: pickedImage)
  }

}

extension ListVC {
  private func tryFoundQRCodeIn(image: UIImage) {
    if let qrString = image.qrCodeString(), let hCert = HCert(from: qrString, applicationType: .wallet) {
        saveQrCode(cert: hCert)
        return
    }
    self.saveImage(image: image)
  }
  
  private func saveQrCode(cert: HCert) {
    presentViewer(for: cert, with: nil, isSaved: false)
  }
  
  private func saveImage(image: UIImage) {
    
  }
}

extension ListVC: UIDocumentPickerDelegate {
  func convertPDF(at sourceURL: URL, dpi: CGFloat = 200) throws -> [UIImage] {
    let pdfDocument = CGPDFDocument(sourceURL as CFURL)!
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue
    
    var images = [UIImage]()
    DispatchQueue.concurrentPerform(iterations: pdfDocument.numberOfPages) { index in
      // Page number starts at 1, not 0
      let pdfPage = pdfDocument.page(at: index + 1)!
      
      let mediaBoxRect = pdfPage.getBoxRect(.mediaBox)
      let scale = dpi / 72.0
      let width = Int(mediaBoxRect.width * scale)
      let height = Int(mediaBoxRect.height * scale)
      
      let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo)!
      context.interpolationQuality = .high
      context.setFillColor(UIColor.white.cgColor)
      context.fill(CGRect(x: 0, y: 0, width: width, height: height))
      context.scaleBy(x: scale, y: scale)
      context.drawPDFPage(pdfPage)
      
      let image = context.makeImage()!
      images.append(UIImage(cgImage: image))
    }
    return images
  }
  
  func savePDFFile() {
//    let pdfView = PDFView()
    //pdfView.document = PDFDocument(data: data)
  }
  
  private func documentPicker(controller: UIDocumentPickerViewController, didPickDocumentAtURL url: NSURL) {
    if controller.documentPickerMode == UIDocumentPickerMode.import {
          // This is what it should be
          //self.newNoteBody.text = String(contentsOfFile: url.path!)
      }
  }
}
