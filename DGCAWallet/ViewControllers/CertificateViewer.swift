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

import UIKit
import SwiftDGC
import PDFKit

protocol CertificateManaging: AnyObject {
  func certificateViewer(_ controller: CertificateViewerVC, didDeleteCertificate cert: HCert)
  func certificateViewer(_ controller: CertificateViewerVC, didAddCeCertificate cert: HCert)
}

class CertificateViewerVC: UIViewController {
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
  
  var hCert: HCert?
  var certDate: Date?
  var tan: String?
  
  weak var delegate: CertificateManaging?

  public var isSaved = true
  private var isEditMode = false
  
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
    if !isSaved {
      dismissButton.setTitle(l10n("btn.save"), for: .normal)
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
      
      if isEditMode {
        editButton.setTitle("Done", for: .normal)
        deleteButton.isHidden = false
        checkValidityButton.isHidden = true
        dismissButton.isHidden = true
        shareButton.isHidden = true
      } else {
        editButton.setTitle("Edit", for: .normal)
        deleteButton.isHidden = true
        checkValidityButton.isHidden = false
        dismissButton.isHidden = false
        shareButton.isHidden = false
      }
      nameLabel.textColor = .white
      headerBackground.backgroundColor = .walletBlue
    }
    
    checkValidityButton.setTitle(l10n("button_check_validity"), for: .normal)
    view.layoutIfNeeded()
  }

  @IBAction func closeButtonClick() {
    if isSaved {
       dismiss(animated: true, completion: nil)
    } else {
      saveCert()
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
    
    showAlert( title: l10n("cert.delete.title"), subtitle: l10n("cert.delete.body"),
      actionTitle: l10n("btn.confirm"), cancelTitle: l10n("btn.cancel")) { [weak self] in
        if $0 {
          DataCenter.localDataManager.remove(withDate: certDate) {[weak self] _ in
            DispatchQueue.main.async {
              self?.delegate?.certificateViewer(self!, didDeleteCertificate: self!.hCert!)
              self?.dismiss(animated: true, completion: nil)
            }
          } // LocalData
        }
      }
  }
  
  func saveCert() {
    showInputDialog(title: l10n("tan.confirm.title"), subtitle: l10n("tan.confirm.text"), actionTitle: l10n("btn.confirm"), inputPlaceholder: l10n("tan.confirm.placeholder") ) { [weak self] in
      guard let cert = self?.hCert else { return }
        
      GatewayConnection.claim(cert: cert, with: $0) { success, newTan in
        if success {
          guard let cert = self?.hCert else { return }
            
          DataCenter.localDataManager.add(cert, with: newTan) { _ in
            DispatchQueue.main.async {
              self?.showAlert(title: l10n("tan.confirm.success.title"), subtitle: l10n("tan.confirm.success.text")) { _ in
                self?.dismiss(animated: true) {
                  self?.delegate?.certificateViewer(self!, didAddCeCertificate: cert)
                }
              }
            }
          }
        } else {
          DispatchQueue.main.async {
            self?.showAlert(title: l10n("tan.confirm.fail.title"), subtitle: l10n("tan.confirm.fail.text"))
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
    let menuActionSheet =  UIAlertController(title: l10n("share.qr.code"), message: l10n("want.share"),
        preferredStyle: .actionSheet)
    menuActionSheet.addAction(UIAlertAction(title: l10n("image.export"), style: .default, handler: { [weak self] _ in
          self?.shareQRCodeLikeImage()
        }))
    menuActionSheet.addAction(UIAlertAction(title: l10n("pdf.export"), style: .default, handler: { [weak self] _ in
          self?.shareQrCodeLikePDF()
        }))
    menuActionSheet.addAction(UIAlertAction(title: l10n("cancel"), style: .cancel, handler: nil))
    present(menuActionSheet, animated: true, completion: nil)
  }
}

extension CertificateViewerVC {
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
