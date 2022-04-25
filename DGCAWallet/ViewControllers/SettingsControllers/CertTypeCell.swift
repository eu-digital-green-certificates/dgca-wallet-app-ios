//
/*-
 * ---license-start
 * eu-digital-green-certificates / dgca-verifier-app-ios
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
//  CertTypeCell.swift
//  DGCAWallet
//  
//  Created by Igor Khomiak on 10.04.2022.
//


import UIKit
import DGCVerificationCenter
import DGCCoreLibrary

class CertTypeCell: UITableViewCell {
    
    @IBOutlet fileprivate weak var certTypeName: UILabel!
    @IBOutlet fileprivate weak var certTaskName: UILabel!
    @IBOutlet fileprivate weak var lastUpdateLabel: UILabel!
    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!

    var delegate: DataManagingProtocol?
    
    var applicant: ApplicableInspector? {
        didSet {
            certTypeName.text = applicant?.type.certificateDescription
            certTaskName.text = applicant?.type.certificateTaskDescription
            
            let dateString = applicant?.inspector.lastUpdate.dateString ?? ""
            lastUpdateLabel.text = "Last updated: " + dateString
        }
    }
    
    @IBAction func reloadDataAction() {
        activityIndicator.startAnimating()
        applicant?.inspector.updateLocallyStoredData(appType: .wallet) { [weak self] rezult in
            if case let .failure(error) = rezult {
                self?.delegate?.loadingInspector(self!.applicant!, didFailLoadingDataWith: error)
                return
            }
            self?.activityIndicator.stopAnimating()
            self?.delegate?.loadingInspector(self!.applicant!, didFinishLoadingData: true)
        }
    }
}
