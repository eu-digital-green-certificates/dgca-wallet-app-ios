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
//  PDFViewerController.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 25.08.2021.
//  


import UIKit
import PDFKit
import SwiftDGC

class PDFViewerController: UIViewController {

  @IBOutlet fileprivate weak var closeButton: UIButton!
  @IBOutlet fileprivate weak var shareButton: UIButton!
  @IBOutlet fileprivate weak var pdfView: UIView!
  
  var pdfViewer: PDFView?

  var savedPDF: SavedPDF? {
    didSet {
      setupView()
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
  }
  
  private func setupView() {
    guard let savedPDF = savedPDF, let pdfView = pdfView else { return }
      
    if pdfViewer == nil {
      pdfViewer = PDFView(frame: pdfView.bounds)
    }
    pdfViewer?.autoScales = true
    pdfView.addSubview(pdfViewer!)
    pdfViewer?.document = savedPDF.pdf
    closeButton.setTitle("Done".localized, for: .normal)
    shareButton.setTitle("Share".localized, for: .normal)
    navigationItem.title = savedPDF.fileName
  }
  
  func setPDF(pdf: SavedPDF) {
    savedPDF = pdf
  }
  
  @IBAction func shareAction(_ sender: Any) {
    guard let savedPDF = savedPDF else { return }
      
    let pdfToShare = [ savedPDF.pdfData ]
    let activityViewController = UIActivityViewController(activityItems: pdfToShare as [Any],
        applicationActivities: nil)
    activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
    self.present(activityViewController, animated: true, completion: nil)
  }
  
  @IBAction func closeAction(_ sender: Any) {
    self.dismiss(animated: true)
  }
}
