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
//  MainListController.swift
//  DGCAWallet
//  
//  Created by Yannick Spreen on 4/25/21.
//  

// swiftlint:disable file_length

import UIKit
import SwiftDGC
import UniformTypeIdentifiers
import MobileCoreServices

protocol DismissControllerDelegate: AnyObject {
  func userDidDissmiss(_ controller: UIViewController)
}

class MainListController: UIViewController {
  fileprivate enum SegueIdentifiers {
    static let showScannerSegue = "showScannerSegue"
    static let showServicesList = "showServicesList"
    static let showSettingsController = "showSettingsController"
    static let showCertificateViewer = "showCertificateViewer"
    static let showPDFViewer = "showPDFViewer"
    static let showImageViewer = "showImageViewer"
  }

  private enum TableSection: Int, CaseIterable {
    case certificates, images, pdfs
  }
  
  @IBOutlet fileprivate weak var addButton: RoundedButton!
  @IBOutlet fileprivate weak var table: UITableView!
  @IBOutlet fileprivate weak var emptyView: UIView!
  @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!
  @IBOutlet fileprivate weak var titleLabel: UILabel!

  var downloadedDataHasExpired: Bool {
    return DataCenter.lastFetch.timeIntervalSinceNow < -SharedConstants.expiredDataInterval
  }
  
  private var scannedToken: String = ""
  private var loading = false
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    self.titleLabel.text = "Certificate Wallet".localized
    self.addButton.setTitle("Add New".localized, for: .normal)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    appDelegate?.isNFCFunctionality = false
    if #available(iOS 13.0, *) {
      let scene = self.sceneDelegate
      scene?.isNFCFunctionality = false
    }
    self.reloadTable()
  }
    
  // MARK: - Private UI methods
  private func reloadAllComponents(completion: @escaping DataCompletionHandler) {
    DataCenter.initializeAllStorageData { result in
      completion(.success(true))
    }
  }
  
  private func startActivity() {
    loading = true
    activityIndicator.startAnimating()
    addButton.isEnabled = false
    addButton.backgroundColor = UIColor.walletLightBlue
  }
 
  private func stopActivity() {
    loading = false
    activityIndicator.stopAnimating()
    addButton.isEnabled = true
    addButton.backgroundColor = UIColor.walletBlue
  }
  
  private func reloadTable() {
    emptyView.alpha = listCertElements.isEmpty && listImageElements.isEmpty && listPdfElements.isEmpty ? 1 : 0
    table.reloadData()
  }

  // MARK: Actions
  @IBAction func addNew() {
    guard loading == false else { return }
    
    let menuActionSheet = UIAlertController(title: "Add new?".localized, message: "Do you want to add new certificate, image or PDF file?".localized,
      preferredStyle: UIAlertController.Style.actionSheet)
    
    menuActionSheet.addAction(UIAlertAction(title: "Scan certificate".localized, style: UIAlertAction.Style.default, handler: {[weak self] _ in
        self?.scanNewCertificate()
      })
    )
    menuActionSheet.addAction(UIAlertAction(title: "Image import".localized, style: UIAlertAction.Style.default, handler: { [weak self] _ in
        self?.addImageActivity()
      })
    )
    menuActionSheet.addAction(UIAlertAction(title: "PDF Import".localized, style: UIAlertAction.Style.default, handler: { [weak self] _ in
        self?.addPdf()
      })
    )
    menuActionSheet.addAction(UIAlertAction(title: "NFC Import".localized, style: UIAlertAction.Style.default, handler: { [weak self] _ in
        self?.scanNFC()
      })
    )
    menuActionSheet.addAction(UIAlertAction(title: "Cancel".localized, style: UIAlertAction.Style.cancel, handler: nil))
    present(menuActionSheet, animated: true, completion: nil)
  }
  
  func onNFCResult(success: Bool, message: String) {
    let barcodeString = message
    guard success, !barcodeString.isEmpty else { return }
    
    DispatchQueue.main.async { [weak self] in
      DGCLogger.logInfo("\(message)")
      let appDelegate = UIApplication.shared.delegate as? AppDelegate
      appDelegate?.isNFCFunctionality = false
      if #available(iOS 13.0, *) {
        let scene = self?.sceneDelegate
        scene?.isNFCFunctionality = false
      }
      
      do {
        let hCert = try HCert(from: barcodeString)
        self?.saveQrCode(cert: hCert)
        
      } catch {
        let alertController: UIAlertController = {
          let controller = UIAlertController(title: "Cannot read NFC".localized,
            message: "An error occurred while reading NFC".localized, preferredStyle: .alert)
          
          let actionRetry = UIAlertAction(title: "Retry".localized, style: .default) { _ in
            self?.scanNFC()
          }
          controller.addAction(actionRetry)
          
          let actionOk = UIAlertAction(title: "OK".localized, style: .default)
          controller.addAction(actionOk)
          return controller
        }()
        self?.present(alertController, animated: true)
      }
    }
  }

  @IBAction func settingsTapped(_ sender: UIButton) {
    self.performSegue(withIdentifier: SegueIdentifiers.showSettingsController, sender: nil)
  }

  // MARK: Tasks
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
    helper.onNFCResult = onNFCResult(success:message:)
    helper.restartSession()
  }
    
  // MARK: Navifation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier {
    case SegueIdentifiers.showScannerSegue:
      guard let scanController = segue.destination as? ScanWalletController else { return }
      scanController.modalPresentationStyle = .fullScreen
      scanController.delegate = self
      scanController.dismissDelegate = self
      
    case SegueIdentifiers.showSettingsController:
      guard let navController = segue.destination as? UINavigationController,
        let serviceController = navController.viewControllers.first as? SettingsTableController else { return }
      serviceController.dismissDelegate = self

    case SegueIdentifiers.showServicesList:
      guard let serviceController = segue.destination as? ServerListController else { return }
      guard let listOfServices = sender as? ServerListResponse else { return }
      serviceController.serverListInfo = listOfServices
      serviceController.dismissDelegate = self
      
    case SegueIdentifiers.showPDFViewer:
      guard let serviceController = segue.destination as? PDFViewerController else { return }
      guard let pdf = sender as? SavedPDF else { return }
      serviceController.setPDF(pdf: pdf)
      serviceController.dismissDelegate = self
      
    case SegueIdentifiers.showImageViewer:
      guard let serviceController = segue.destination as? ImageViewerController else { return }
      guard let savedImage = sender as? SavedImage else { return }
      serviceController.setImage(image: savedImage)
      serviceController.dismissDelegate = self
      
    case SegueIdentifiers.showCertificateViewer:
      guard let serviceController = segue.destination as? CertificateViewerController else { return }
      if let savedCertificate = sender as? DatedCertString {
        serviceController.hCert = savedCertificate.cert
        serviceController.isSaved = true
        serviceController.certDate = savedCertificate.date
        serviceController.tan = savedCertificate.storedTAN
      } else if let certificate = sender as? HCert {
        serviceController.hCert = certificate
        serviceController.isSaved = false
      }
      serviceController.dismissDelegate = self
      serviceController.delegate = self
      
    default:
      break
    }
  }
}

// MARK: - ScanWalletDelegate
extension MainListController: ScanWalletDelegate {
  func walletController(_ controller: ScanWalletController, didFailWithError error: CertificateParsingError) {
    DispatchQueue.main.async {
      self.showInfoAlert(withTitle: "Barcode reading Error".localized, message: "Something went wrong.".localized)
    }
  }
  
  func disableBackgroundDetection() {
    SecureBackground.paused = true
  }

  func enableBackgroundDetection() {
    SecureBackground.paused = false
  }

  func walletController(_ controller: ScanWalletController, didScanCertificate certificate: HCert) {
    DispatchQueue.main.async { [weak self] in
      self?.dismiss(animated: true, completion: {
        self?.performSegue(withIdentifier: SegueIdentifiers.showCertificateViewer, sender: certificate)
      })
    }
  }
  
  func walletController(_ controller: ScanWalletController, didScanInfo ticketing: SwiftDGC.CheckInQR) {
    if scannedToken == ticketing.token {
      return
    }
    scannedToken = ticketing.token
    startActivity()
    IdentityService.requestListOfServices(ticketingInfo: ticketing) { [weak self] services, error in
      guard error == nil else {
        self?.showInfoAlert(withTitle: "This certificate is not supported".localized, message: "")
        return
      }
      DispatchQueue.main.async {
        self?.stopActivity()
        self?.dismiss(animated: true, completion: {
          self?.scannedToken = ""
          self?.performSegue(withIdentifier: SegueIdentifiers.showServicesList, sender: services)
        })
      }
    }
  }
}

// MARK: CertificateManaging
extension MainListController: CertificateManaging {
  func certificateViewer(_ controller: CertificateViewerController, didDeleteCertificate cert: HCert) {
      DispatchQueue.main.async { [weak self] in
        self?.reloadTable()
      }
  }
  
  func certificateViewer(_ controller: CertificateViewerController, didAddCeCertificate cert: HCert) {
    DispatchQueue.main.async { [weak self] in
      self?.reloadTable()
    }
  }
}

// MARK: UITable delegate
extension MainListController: UITableViewDelegate, UITableViewDataSource {
  var listCertElements: [DatedCertString] {
    return DataCenter.certStrings.reversed()
  }

  var listImageElements: [SavedImage] {
    return DataCenter.images
  }

  var listPdfElements: [SavedPDF] {
    return DataCenter.pdfs
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
        return !listCertElements.isEmpty ? "Certificates".localized : nil
      case TableSection.images.rawValue:
        return !listImageElements.isEmpty ? "Images".localized : nil
      case TableSection.pdfs.rawValue:
        return !listPdfElements.isEmpty ? "PDF files".localized : nil
      default:
          return nil
      }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      switch indexPath.section {
      case TableSection.certificates.rawValue:
        guard let walletCell = table.dequeueReusableCell(withIdentifier: "walletCell", for: indexPath) as? WalletCell
        else { return UITableViewCell() }
        
        walletCell.setupCell(listCertElements[indexPath.row])
        return walletCell
          
      case TableSection.images.rawValue:
        guard let imageCell = table.dequeueReusableCell(withIdentifier: "ImageTableViewCell", for: indexPath) as? ImageTableViewCell
        else { return UITableViewCell() }
        
        imageCell.setImage(image: listImageElements[indexPath.row])
        return imageCell
          
      case TableSection.pdfs.rawValue:
        guard let imageCell = table.dequeueReusableCell(withIdentifier: "PDFTableViewCell", for: indexPath) as? PDFTableViewCell
        else { return UITableViewCell() }
           
        imageCell.setPDF(pdf: listPdfElements[indexPath.row])
        return imageCell
          
      default:
          return UITableViewCell()
      }
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard loading == false else { return }
    
    table.deselectRow(at: indexPath, animated: true)
    switch indexPath.section {
      case TableSection.certificates.rawValue:
        self.performSegue(withIdentifier: SegueIdentifiers.showCertificateViewer, sender: listCertElements[indexPath.row])
          
      case TableSection.images.rawValue:
        self.performSegue(withIdentifier: SegueIdentifiers.showImageViewer, sender: listImageElements[indexPath.row])

      case TableSection.pdfs.rawValue:
        self.performSegue(withIdentifier: SegueIdentifiers.showPDFViewer, sender: listPdfElements[indexPath.row])
      
      default:
          break
    }
  }

  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
      switch indexPath.section {
      case TableSection.certificates.rawValue:
        let savedCert = listCertElements[indexPath.row]
        showAlert( title: "Delete Certificate".localized, subtitle: "cert.delete.body".localized,
                   actionTitle: "Confirm".localized, cancelTitle: "Cancel".localized) { [weak self] in
        if $0 {
          self?.startActivity()
          DataCenter.localDataManager.remove(withDate: savedCert.date) { _ in
            DispatchQueue.main.async {
              self?.table.reloadData()
              self?.stopActivity()
              self?.reloadTable()
            }
          } // LocalData
        }
      }
      
      case TableSection.images.rawValue:
        let savedImage = listImageElements[indexPath.row]
        showAlert( title: "Delete Certificate".localized, subtitle: "cert.delete.body".localized,
      actionTitle: "Confirm".localized, cancelTitle:"Cancel".localized) { [weak self] in
          if $0 {
            self?.startActivity()
            DataCenter.imageDataManager.deleteImage(with: savedImage.identifier) { _ in
              DispatchQueue.main.async {
                self?.stopActivity()
                self?.reloadTable()
              }
            }
          }
        }
      case TableSection.pdfs.rawValue:
        let savedPDF = listPdfElements[indexPath.row]
        showAlert( title: "Delete Certificate".localized, subtitle: "cert.delete.body".localized,
                   actionTitle: "Confirm".localized, cancelTitle: "Cancel".localized) { [weak self] in
          if $0 {
            self?.startActivity()
            DataCenter.pdfDataManager.deletePDF(with: savedPDF.identifier) { _ in
              DispatchQueue.main.async {
                self?.stopActivity()
                self?.reloadTable()
              }
            }
          }
        }
      default:
          break
      }
  }
}

// MARK: UIImagePicker delegate
extension MainListController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  private func addImageActivity() {
    let alert = UIAlertController(title: "Get Image from".localized, message: nil, preferredStyle: .actionSheet)
    let cameraAction = UIAlertAction(title: "Camera".localized, style: .default) {[weak self] _ in
      alert.dismiss(animated: true, completion: nil)
      self?.openCamera()
    }
    let galleryAction = UIAlertAction(title: "Gallery".localized, style: .default) {[weak self] _ in
      alert.dismiss(animated: true, completion: nil)
      self?.openGallery()
    }
    let cancelAction = UIAlertAction(title: "Cancel".localized, style: .cancel)
    
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
            let controller = UIAlertController(title:"Cannot scan".localized, message: "You don't have a camera.".localized,
                 preferredStyle: .alert)
            let action = UIAlertAction(title: "OK".localized, style: .default)
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

// MARK: QR Code, PDF. Image sources
extension MainListController {
  private func tryFoundQRCodeIn(image: UIImage) {
    if let qrString = image.qrCodeString() {
      do {
        let hCert = try HCert(from: qrString)
        self.saveQrCode(cert: hCert)
      } catch {
      }
      
    } else {
      self.saveImage(image: image)
    }
  }
  
  private func saveQrCode(cert: HCert) {
    self.performSegue(withIdentifier: SegueIdentifiers.showCertificateViewer, sender: cert)
  }
  
  private func saveImage(image: UIImage) {
    showInputDialog(title: "Save image".localized, subtitle: "Please enter the image name".localized,
          inputPlaceholder: "filename".localized) { [weak self] fileName in
      let savedImg = SavedImage(fileName: fileName ?? UUID().uuidString, image: image)
      
      self?.startActivity()
      DataCenter.imageDataManager.add(savedImage: savedImg) { _ in
        DispatchQueue.main.async {
          self?.stopActivity()
          self?.table.reloadData()
          let rowCount = DataCenter.images.count
            if rowCount > 0 {
              let scrollToNum = rowCount - 1
              let path = IndexPath(row: scrollToNum, section: TableSection.images.rawValue)
              self?.table.scrollToRow(at: path, at: .bottom, animated: true)
              self?.table.selectRow(at: path, animated: true, scrollPosition: .bottom)
              DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(350)) {
                self?.table.deselectRow(at: path, animated: true)
              }
            }
          }
      } // end add
    }
  }
}

// MARK: PDF Document Delegate
extension MainListController: UIDocumentPickerDelegate {
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
        if let qrString = image.qrCodeString() {
          do {
             let hCert = try HCert(from: qrString)
            self.saveQrCode(cert: hCert)
          } catch {
          }
          return
        }
      }
      savePDFFile(url: url)
  }
  
  private func savePDFFile(url: NSURL) {
    showInputDialog(title: "Save PDF file".localized, subtitle: "Please enter the pdf file name".localized,
          inputPlaceholder: "filename".localized) { [weak self] fileName in
      let pdf = SavedPDF(fileName: fileName ?? UUID().uuidString, pdfUrl: url as URL)
      
      self?.startActivity()
      DataCenter.pdfDataManager.add(savedPdf: pdf) { _ in
        DispatchQueue.main.async {
          self?.stopActivity()
          self?.table.reloadData()
          let rowsCount = DataCenter.pdfs.count
           if rowsCount > 0 {
            let scrollToNum = rowsCount-1
            let path = IndexPath(row: scrollToNum, section: TableSection.pdfs.rawValue)
            self?.table.scrollToRow(at: path, at: .bottom, animated: true)
            self?.table.selectRow(at: path, animated: true, scrollPosition: .bottom)
            // let's add time for app to scroll down (0.35 sec)
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(350)) {
              self?.table.deselectRow(at: path, animated: true)
            }
          }
        }
      } // end add
    } // end alert action
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


// MARK: DismissController Delegate
extension MainListController: DismissControllerDelegate {
  func userDidDissmiss(_ controller: UIViewController) {
    if downloadedDataHasExpired {
      self.navigationController?.popViewController(animated: false)
    }
  }
}
