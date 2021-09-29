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
//  QRTicketCodeDetailsViewController.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 16.09.2021.
//  
        

import UIKit
import SwiftDGC

class TicketCodeAcceptViewController: UIViewController {

  @IBOutlet weak var certificateTitle: UILabel!
  @IBOutlet weak var validToLabel: UILabel!
  @IBOutlet weak var consetsLabel: UILabel!
  @IBOutlet weak var infoLabel: UILabel!
  
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var grandButton: UIButton!
  
  private var validationServiceInfo : ServerListResponse?
  private var accessTokenInfo       : AccessTokenResponse?
  
  override func viewDidLoad() {
        super.viewDidLoad()
    }

  private func setuppView() { }
  
  public func setCertsWith(_ validationInfo: ServerListResponse,_ accessTokenModel : AccessTokenResponse) {
    validationServiceInfo = validationInfo
    accessTokenInfo = accessTokenModel
  }
  
  @IBAction func cancelButtonAction(_ sender: Any) {
  }
  
  @IBAction func grandButtonAction(_ sender: Any) {
    
  }

}
