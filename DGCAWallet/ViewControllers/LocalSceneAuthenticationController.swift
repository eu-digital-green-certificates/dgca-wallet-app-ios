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
//  LocalSceneAuthenticationController.swift
//  DGCAWallet
//  
//  Created by Igor Khomiak on 03.05.2022.
//  
        

import UIKit

typealias AuthenticationCompletionHandler = (Bool) -> Void

class LocalSceneAuthenticationController: UIViewController {

    let showHomeLoadingData = "showHomeLoadingData"
    var delegate: SecureAuthorising?
    
    @IBOutlet fileprivate weak var appNameLabel: UILabel!
    @IBOutlet fileprivate weak var messageLabel: UILabel!
    @IBOutlet fileprivate weak var tryAgainButton: UIButton!

    
    func setupInterface() {
        appNameLabel.text = "Wallet App".localized
        messageLabel.text = "Please authenticate to access the secure data.".localized
        tryAgainButton.setTitle("Try again".localized, for: .normal)
    }
    
    @IBAction func tryAgainAction() {
        self.delegate?.tryAgainAuthentication()
    }
}
