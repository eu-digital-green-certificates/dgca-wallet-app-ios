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

// swiftlint:disable file_length

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
  
    fileprivate enum SegueIdentifiers {
      static let showScannerSegue = "showScannerSegue"
      static let showServicesList = "showServicesList"
      static let showSettingsController = "showSettingsController"
      static let showPDFViewer = "showPDFViewer"
      static let showImageViewer = "showImageViewer"
    }

  private enum TableSection: Int, CaseIterable {
    case certificates, images, pdfs
  }
  
  @IBOutlet weak var addButton: RoundedButton!
  @IBOutlet weak var table: UITableView!
  @IBOutlet weak var emptyView: UIView!

  private var scannedToken: String = ""

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      self.reloadAllComponents()
      
      let appDelegate = UIApplication.shared.delegate as? AppDelegate
      appDelegate?.isNFCFunctionality = false
      if #available(iOS 13.0, *) {
        let scene = self.sceneDelegate
        scene?.isNFCFunctionality = false
      }
  }

  func reloadAllComponents() {
    ImageDataStorage.initialize {
      PdfDataStorage.initialize {
        DispatchQueue.main.async {
          self.reloadTable()
        }
      }
    }
  }
  
  @IBAction func addNew() {
    let menuActionSheet = UIAlertController(title: l10n("add.new"),
       message: l10n("want.add"),
       preferredStyle: UIAlertController.Style.actionSheet)
       menuActionSheet.addAction(UIAlertAction(title: l10n("scan.certificate"),
       style: UIAlertAction.Style.default,
       handler: {[weak self] _ in
           self?.scanNewCertificate()
       }))
    menuActionSheet.addAction(UIAlertAction(title: l10n("image.import"),
        style: UIAlertAction.Style.default,
        handler: { [weak self] _ in
      self?.addImageActivity()
    }))
    menuActionSheet.addAction(UIAlertAction(title: l10n("pdf.import"),
        style: UIAlertAction.Style.default,
        handler: { [weak self] _ in
      self?.addPdf()
    }))
    menuActionSheet.addAction(UIAlertAction(title: l10n("nfc.import"),
        style: UIAlertAction.Style.default,
        handler: { [weak self] _ in
      self?.scanNFC()
    }))
    menuActionSheet.addAction(UIAlertAction(title: l10n("cancel"),
        style: UIAlertAction.Style.cancel,
        handler: nil))
    present(menuActionSheet, animated: true, completion: nil)
  }
  
  private func scanNewCertificate() {
      performSegue(withIdentifier: SegueIdentifiers.showScannerSegue, sender: nil)
  }

  private func addPdf() {
    let pdfPicker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
      let supportedTypes: [UTType] = [UTType.pdf]
      pdfPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
    } else {
      pdfPicker = UIDocumentPickerViewController(documentTypes: [kUTTypePDF as String], in: .open)
    }
    pdfPicker.delegate = self
    present(pdfPicker, animated: true, completion: nil)
  }

  private func scanNFC() {
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    appDelegate?.isNFCFunctionality = true
    if #available(iOS 13.0, *) {
      let scene = self.sceneDelegate
      scene?.isNFCFunctionality = true
    }
    let helper = NFCHelper()
    helper.onNFCResult = onNFCResult(success:msg:)
    helper.restartSession()
  }

  func onNFCResult(success: Bool, msg: String) {
    DispatchQueue.main.async { [weak self] in
      print("\(msg)")
      let appDelegate = UIApplication.shared.delegate as? AppDelegate
      appDelegate?.isNFCFunctionality = false
      if #available(iOS 13.0, *) {
        let scene = self?.sceneDelegate
        scene?.isNFCFunctionality = false
      }
      if success, let hCert = HCert(from: msg, applicationType: .wallet) {
        self?.saveQrCode(cert: hCert)
      } else {
        let alertController: UIAlertController = {
            let controller = UIAlertController(title: l10n("error"), message: l10n("read.dcc.from.nfc"),
                preferredStyle: .alert)
          let actionRetry = UIAlertAction(title: l10n("retry"), style: .default) { _ in
            self?.scanNFC()
          }
            controller.addAction(actionRetry)
          let actionOk = UIAlertAction(title: l10n("ok"), style: .default)
          controller.addAction(actionOk)
            return controller
        }()
        self?.present(alertController, animated: true)
      }
    }
  }
  
  @IBAction func settingsTapped(_ sender: UIButton) {
    guard let settingsVC = UIStoryboard(name: "Settings", bundle: nil).instantiateInitialViewController(),
          let viewer = settingsVC as? SettingsVC else { return }
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

    present(fpc, animated: true, completion: nil)
  }

  func reloadTable() {
    emptyView.alpha = listCertElements.isEmpty
      && listImageElements.isEmpty
      && listPdfElements.isEmpty ? 1 : 0
    table.reloadData()
  }

  func presentViewer(for certificate: HCert, with tan: String? = nil, isSaved: Bool = true) {
    guard let certViewerController = UIStoryboard(name: "CertificateViewer", bundle: nil).instantiateInitialViewController() as? CertificateViewerVC else { return }

    certViewerController.isSaved = isSaved
    certViewerController.hCert = certificate
    certViewerController.tan = tan
    certViewerController.childDismissedDelegate = self
    let fpc = FloatingPanelController()
    fpc.set(contentViewController: certViewerController)
    fpc.isRemovalInteractionEnabled = true // Let it removable by a swipe-down
    fpc.layout = FullFloatingPanelLayout()
    fpc.surfaceView.layer.cornerRadius = 24.0
    fpc.surfaceView.clipsToBounds = true
    fpc.delegate = self

    present(fpc, animated: true, completion: nil)
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      switch segue.identifier {
      case SegueIdentifiers.showScannerSegue:
          guard let scanController = segue.destination as? ScanWalletController else { return }
          
          scanController.modalPresentationStyle = .fullScreen
          scanController.delegate = self
          
      case SegueIdentifiers.showServicesList:
          guard let serviceController = segue.destination as? ServersListVC else { return }
          guard let listOfServices = sender as?  ServerListResponse else { return }
          
          serviceController.setServices(info: listOfServices)
      case SegueIdentifiers.showPDFViewer:
        guard let serviceController = segue.destination as? PDFViewerVC else { return }
        guard let pdf = sender as? SavedPDF else { return }
        serviceController.setPDF(pdf: pdf)

      case SegueIdentifiers.showImageViewer:
        guard let serviceController = segue.destination as? ImageViewerVC else { return }
        guard let savedImage = sender as? SavedImage else { return }
        serviceController.setImage(image: savedImage)
      default:
          break
      }
  }
}

extension ListVC: CertViewerDelegate {
  func childDismissed(_ newCertAdded: Bool) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
        self.reloadTable()
    }
  }
}

extension ListVC: ScanWalletDelegate {
  func disableBackgroundDetection() {
    SecureBackground.paused = true
  }

  func enableBackgroundDetection() {
    SecureBackground.paused = false
  }

  func walletController(_ controller: ScanWalletController, didScanCertificate certificate: HCert) {
    DispatchQueue.main.async { [weak self] in
        self?.dismiss(animated: true, completion: {
            self?.presentViewer(for: certificate, isSaved: false)
        })
    }
  }
  
  func walletController(_ controller: ScanWalletController, didScanInfo ticketing: SwiftDGC.CheckInQR) {
    if scannedToken == ticketing.token || navigationController?.viewControllers.last is ServersListVC {
      return
    }
    scannedToken = ticketing.token
    IdentityService.requestListOfServices(ticketingInfo: ticketing) { [weak self] services in
      self?.scannedToken = ""

      DispatchQueue.main.async {
          self?.dismiss(animated: true, completion: {
              self?.performSegue(withIdentifier: SegueIdentifiers.showServicesList, sender: services)
          })
      }
    }
  }
}

extension ListVC: UITableViewDataSource {
  var listCertElements: [DatedCertString] {
    LocalData.sharedInstance.certStrings.reversed()
  }

  var listImageElements: [SavedImage] {
    ImageDataStorage.sharedInstance.images
  }

  var listPdfElements: [SavedPDF] {
    PdfDataStorage.sharedInstance.pdfs
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      switch section {
      case TableSection.certificates.rawValue:
          return listCertElements.count
      case TableSection.images.rawValue:
          return listImageElements.count
      case  TableSection.pdfs.rawValue:
          return listPdfElements.count
      default:
          return .zero
      }
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
      return TableSection.allCases.count
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
      switch section {
      case TableSection.certificates.rawValue:
          return l10n("section.certificates")
      case TableSection.images.rawValue:
          return l10n("section.images")
      case  TableSection.pdfs.rawValue:
          return l10n("section.pdf")
      default:
          return ":"
      }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      switch indexPath.section {
      case TableSection.certificates.rawValue:
        guard let walletCell = table.dequeueReusableCell(withIdentifier: "walletCell", for: indexPath) as? WalletCell else { return UITableViewCell() }
        
        walletCell.draw(listCertElements[indexPath.row])
        return walletCell
          
      case TableSection.images.rawValue:
          guard let imageCell = table.dequeueReusableCell(withIdentifier: "ImageTableViewCell", for: indexPath) as? ImageTableViewCell else { return UITableViewCell() }
        imageCell.setImage(image: listImageElements[indexPath.row])
        return imageCell
          
      case TableSection.pdfs.rawValue:
          guard let imageCell = table.dequeueReusableCell(withIdentifier: "PDFTableViewCell", for: indexPath) as? PDFTableViewCell else { return UITableViewCell() }
           
        imageCell.setPDF(pdf: listPdfElements[indexPath.row])
        return imageCell
          
      default:
          return UITableViewCell()
      }
  }
}

extension ListVC: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    table.deselectRow(at: indexPath, animated: true)
    switch indexPath.section {
      case TableSection.certificates.rawValue:
          guard let cert = listCertElements[indexPath.row].cert else { return }
          presentViewer(for: cert, with: listCertElements[indexPath.row].storedTAN)
          
      case TableSection.images.rawValue:
        self.performSegue(withIdentifier: SegueIdentifiers.showImageViewer, sender: listImageElements[indexPath.row])

      case TableSection.pdfs.rawValue:
        self.performSegue(withIdentifier: SegueIdentifiers.showPDFViewer, sender: listPdfElements[indexPath.row])
        
      default:
          break
    }
  }

  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
    forRowAt indexPath: IndexPath
  ) {
      switch indexPath.section {
      case 0:
          let savedCert = listCertElements[indexPath.row]
          showAlert( title: l10n("cert.delete.title"), subtitle: l10n("cert.delete.body"),
            actionTitle: l10n("btn.confirm"), cancelTitle: l10n("btn.cancel")) { [weak self] in
                if $0 {
                LocalData.remove(withTAN: savedCert.storedTAN)
                LocalData.sharedInstance.save()
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
                  self?.reloadTable()
                }
              }
            }
      case 1:
          //TODO - add remove images
          break
      case 2:
          //TODO - add remove pdfs
          break
      case 3:
          break
      default:
          break
      }
  }
}

extension ListVC: FloatingPanelControllerDelegate {
  func floatingPanel(_ fpc: FloatingPanelController, shouldRemoveAt location: CGPoint,
    with velocity: CGVector) -> Bool {
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
  
  private func addImageActivity() {
    let alert = UIAlertController(title: l10n("get.image.from"), message: nil, preferredStyle: .actionSheet)
    let cameraAction = UIAlertAction(title: l10n("camera"), style: .default) {[weak self] _ in
      alert.dismiss(animated: true, completion: nil)
      self?.openCamera()
    }
    let galleryAction = UIAlertAction(title: l10n("galery"), style: .default) {[weak self] _ in
      alert.dismiss(animated: true, completion: nil)
      self?.openGallery()
    }
    let cancelAction = UIAlertAction(title: l10n("cancel"), style: .cancel)
    
    // Add the actions
    alert.addAction(cameraAction)
    alert.addAction(galleryAction)
    alert.addAction(cancelAction)
    present(alert, animated: true, completion: nil)
  }
    
  private func openCamera() {
      if UIImagePickerController.isSourceTypeAvailable(.camera) {
          let picker = UIImagePickerController()
          picker.delegate = self
          picker.sourceType = .camera
          present(picker, animated: true, completion: nil)
      } else {
          let alertController: UIAlertController = {
              let controller = UIAlertController(title: l10n("error"),
                 message: l10n("dont.have.camera"),
                 preferredStyle: .alert)
              let action = UIAlertAction(title: l10n("ok"), style: .default)
              controller.addAction(action)
              return controller
          }()
          self.present(alertController, animated: true)
      }
  }
    
  func openGallery() {
      let picker = UIImagePickerController()
      picker.delegate = self

      picker.sourceType = .photoLibrary
      present(picker, animated: true, completion: nil)
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      picker.dismiss(animated: true, completion: nil)
  }

  func imagePickerController(_ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
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
    showInputDialog(
      title: l10n("image.confirm.title"),
      subtitle: l10n("image.confirm.text"),
      inputPlaceholder: l10n("image.confirm.placeholder")
    ) { fileName in
      ImageDataStorage.sharedInstance.add(savedImage: SavedImage(fileName: fileName ?? UUID().uuidString, image: image))
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {  [weak self] in
            self?.reloadTable()
        }
    }
  }
}

extension ListVC: UIDocumentPickerDelegate {
  private func convertPDF(at sourceURL: URL, dpi: CGFloat = 200) throws -> [UIImage] {
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
      let context = CGContext(data: nil,
          width: width,
          height: height,
          bitsPerComponent: 8,
          bytesPerRow: 0,
          space: colorSpace,
          bitmapInfo: bitmapInfo)!
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
  
  private func checkQRCodesInPDFFile(url: NSURL) {
      guard let images = try? convertPDF(at: url as URL), !images.isEmpty else {
          savePDFFile(url: url)
          return
      }
      for image in images {
        if let qrString = image.qrCodeString(), let hCert = HCert(from: qrString, applicationType: .wallet) {
            saveQrCode(cert: hCert)
            return
        }
      }
      savePDFFile(url: url)
  }
  
  private func savePDFFile(url: NSURL) {
    showInputDialog(
      title: l10n("pdf.confirm.title"),
      subtitle: l10n("pdf.confirm.text"),
      inputPlaceholder: l10n("pdf.confirm.placeholder")
    ) { fileName in
      PdfDataStorage.sharedInstance.add(savedPdf: SavedPDF(fileName: fileName ?? UUID().uuidString, pdfUrl: url as URL))
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {  [weak self] in
            self?.reloadTable()
        }
    }
  }
  
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let url = urls.first else { return }

    if controller.documentPickerMode == .import {
      checkQRCodesInPDFFile(url: url as NSURL)
    }
  }
  
  private func documentPicker(controller: UIDocumentPickerViewController, didPickDocumentAtURL url: NSURL) {
    if controller.documentPickerMode == .import {
      checkQRCodesInPDFFile(url: url)
    }
  }
}

