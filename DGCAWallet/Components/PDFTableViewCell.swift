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
//  PDFTableViewCell.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 25.08.2021.
//  
        

import UIKit
import PDFKit
import DCCInspection

class PDFTableViewCell: UITableViewCell {
    
    @IBOutlet fileprivate weak var pdfView: UIView!
    @IBOutlet fileprivate weak var nameLabel: UILabel!
    @IBOutlet fileprivate weak var timeLabel: UILabel!

    private var savedPDF: SavedPDF? {
        didSet {
            setupView()
        }
    }

    private var pdfViewer: PDFView?
    func setPDF(pdf: SavedPDF) {
        savedPDF = pdf
    }
    
    private func setupView() {
        guard let savedPDF = savedPDF else {
            nameLabel.text = ""
            return
        }

        if pdfViewer == nil {
            pdfViewer = PDFView(frame: pdfView.bounds)
            pdfViewer?.autoScales = true
            let scrollView = pdfViewer?.subviews.first as? UIScrollView
            if scrollView != nil {
                scrollView?.isScrollEnabled = false
            }
            if let pdf = pdfViewer {
                pdfView.addSubview(pdf)
            }
        }
        
        if let document = savedPDF.pdf {
            pdfViewer?.document = document
        }
        nameLabel.text = savedPDF.fileName
        timeLabel.text = savedPDF.dateString
    }

    override func prepareForReuse() {
        savedPDF = nil
    }
}
