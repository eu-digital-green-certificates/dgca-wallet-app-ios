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
//  CertificateViewerController.swift
//  DGCAWallet
//
//  Created by Yannick Spreen on 4/19/21.
//

import UIKit
import SwiftDGC
import PDFKit

protocol CertificateManaging: AnyObject {
  func certificateViewer(_ controller: CertificateViewerController, didDeleteCertificate cert: HCert)
  func certificateViewer(_ controller: CertificateViewerController, didAddCeCertificate cert: HCert)
}


class CertificateViewerController: UIViewController {
  private enum Constants {
    static let showValidityController = "showValidityController"
    static let embedCertPagesController = "embedCertPagesController"
  }
  
  @IBOutlet fileprivate weak var headerBackground: UIView!
  @IBOutlet fileprivate weak var nameLabel: UILabel!
  @IBOutlet fileprivate weak var dismissButton: UIButton!
  @IBOutlet fileprivate weak var cancelButton: UIButton!
  @IBOutlet fileprivate weak var shareButton: UIButton!
  @IBOutlet fileprivate weak var editButton: UIButton!
  @IBOutlet fileprivate weak var deleteButton: UIButton!
  @IBOutlet fileprivate weak var checkValidityButton: UIButton!
  @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!

  var hCert: HCert?
  var certDate: Date?
  var tan: String?
  
  weak var delegate: CertificateManaging?

  public var isSaved = true
  private var isEditMode = false
  
  deinit {
      let center = NotificationCenter.default
      center.removeObserver(self)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setupInterface()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    Brightness.reset()
  }
  
  func setupInterface() {
    guard let hCert = hCert else { return }
    
    nameLabel.text = hCert.fullName
    shareButton.setTitle("Share".localized, for: .normal)
    deleteButton.setTitle("Delete Certificate".localized, for: .normal)
    checkValidityButton.setTitle("Check Validity".localized, for: .normal)

    if !isSaved {
      dismissButton.setTitle("Save".localized, for: .normal)
      editButton.isHidden = true
      cancelButton.isHidden = false
      
      deleteButton.isHidden = true
      checkValidityButton.isHidden = true
      shareButton.isHidden = false
      dismissButton.isHidden = false
      nameLabel.textColor = .walletBlack
      headerBackground.backgroundColor = .walletGray10
    } else {
      editButton.isHidden = false
      cancelButton.isHidden = true
      dismissButton.setTitle("Done".localized, for: .normal)
      if isEditMode {
        editButton.setTitle("Done".localized, for: .normal)
        deleteButton.isHidden = false
        checkValidityButton.isHidden = true
        dismissButton.isHidden = true
        shareButton.isHidden = true
      } else {
        editButton.setTitle("Edit".localized, for: .normal)
        deleteButton.isHidden = true
        checkValidityButton.isHidden = false
        dismissButton.isHidden = false
        shareButton.isHidden = false
      }
      nameLabel.textColor = .white
      headerBackground.backgroundColor = .walletBlue
    }
    
    view.layoutIfNeeded()
  }

  @IBAction func closeButtonClick() {
    if isSaved {
       dismiss(animated: true, completion: nil)
    } else {
      activityIndicator.startAnimating()
      saveCert {[weak self] in
        DispatchQueue.main.async {
          self?.activityIndicator.stopAnimating()
        }
      }
    }
  }

  @IBAction func cancelButtonClick() {
    dismiss(animated: true, completion: nil)
  }

  @IBAction func checkValidityAction(_ sender: Any) {
    self.performSegue(withIdentifier: Constants.showValidityController, sender: nil)
  }
  
  @IBAction func editAction() {
    isEditMode = !isEditMode
    setupInterface()
  }

  @IBAction func deleteCertificateAction() {
    guard let certDate = certDate else { return }
    guard let cert = self.hCert else { return }

    showAlert( title: "Delete Certificate".localized, subtitle: "cert.delete.body".localized,
        actionTitle: "Confirm".localized, cancelTitle: "Cancel".localized) { [unowned self] in
      if $0 {
        DataCenter.localDataManager.remove(withDate: certDate) { _ in
          self.delegate?.certificateViewer(self, didDeleteCertificate: cert)
          DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
          }
        } // LocalData
      }
    }
  }
  
  private func saveCert(completion: @escaping CompletionHandler) {
    showInputDialog(title: "Confirm TAN".localized,
        subtitle: "Please enter the TAN that was provided together with your certificate:".localized,
        actionTitle: "Confirm".localized, inputPlaceholder: "XYZ12345" ) { [unowned self] in
      guard let certificate = self.hCert else {
        DGCLogger.logInfo("Certificate error")
        completion()
        return
      }
        
      GatewayConnection.claim(cert: certificate, with: $0) { success, newTan, error in
        guard error == nil else {
          completion()
          DispatchQueue.main.async {
            self.showAlert(title:"Cannot save the Certificate".localized, subtitle: "Check the TAN and try again.".localized)
          }

          DGCLogger.logError(error!)
          return
        }
        
        if success {
					DataCenter.localDataManager.add(certificate, with: newTan) { _ in
						completion()
						DispatchQueue.main.async {
							self.showAlert(title: "Certificate saved successfully".localized, subtitle: "Now it is available in the wallet".localized) { _ in
								self.dismiss(animated: true) {
									self.delegate?.certificateViewer(self, didAddCeCertificate: certificate)
								}
							}
						}
					}
        } else {
          completion()
          DispatchQueue.main.async {
            self.showAlert(title:"Cannot save the Certificate".localized, subtitle: "Check the TAN and try again.".localized)
          }
        }
      }
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier {
    case Constants.showValidityController:
      guard let checkController = segue.destination as? CheckValidityController else { return }
      checkController.setupCheckValidity(with: hCert)
      
    case Constants.embedCertPagesController:
      guard let childController = segue.destination as? CertPagesController else { return }
      childController.embeddingVC = self

    default:
      break
    }
  }
  
  @IBAction func shareAction(_ sender: Any) {
    let menuActionSheet =  UIAlertController(title: "Share QR Code?".localized,
          message: "Do you want to share DCC certificate via image or PDF file?".localized, preferredStyle: .actionSheet)
    menuActionSheet.addAction(UIAlertAction(title: "Export as Image".localized, style: .default, handler: { [weak self] _ in
          self?.shareQRCodeLikeImage()
        }))
    menuActionSheet.addAction(UIAlertAction(title: "Export as PDF".localized, style: .default, handler: { [weak self] _ in
          self?.shareQrCodeLikePDF()
        }))
    menuActionSheet.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
    present(menuActionSheet, animated: true, completion: nil)
  }
}

extension CertificateViewerController {
  private func shareQRCodeLikeImage() {
    guard let hCert = hCert, let savedImage = hCert.qrCode else { return }
      
    let imageToShare = [ savedImage ]
    let activityViewController = UIActivityViewController(activityItems: imageToShare as [Any],
      applicationActivities: nil)
    activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
    self.present(activityViewController, animated: true, completion: nil)
  }
  
  private func shareQrCodeLikePDF() {
    guard let hCert = hCert, let savedImage = hCert.qrCode else { return }
      
    let pdfDocument = PDFDocument()
    let pdfPage = PDFPage(image: savedImage)
    pdfDocument.insert(pdfPage!, at: 0)
    let data = pdfDocument.dataRepresentation()
    let pdfToShare = [ data ]
    let activityViewController = UIActivityViewController(activityItems: pdfToShare as [Any],
      applicationActivities: nil)
    activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
    self.present(activityViewController, animated: true, completion: nil)
  }
}
