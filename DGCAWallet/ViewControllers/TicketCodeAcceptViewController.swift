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
  
  private func setuppView(isValidation: Bool) {
    if isValidation {
      certificateTitle.text = "Vaccination 1 of 1"
      validToLabel.text = "No expiration date"
      consetsLabel.text = "Consent"
      infoLabel.text = "Do you agree share the vaccination certificate 2 with Airline.com?"
    }
  }
  
  public func setCertsWith(_ validationInfo: ServerListResponse,_ accessTokenModel : AccessTokenResponse) {
    validationServiceInfo = validationInfo
    accessTokenInfo = accessTokenModel
    setuppView(isValidation: true)
  }
  
  @IBAction func cancelButtonAction(_ sender: Any) {
    dismiss(animated: true, completion: nil)
  }
  
  @IBAction func grandButtonAction(_ sender: Any) {
    guard let urlPath = accessTokenInfo?.aud!,
          let url = URL(string: urlPath),
          let iv = UserDefaults.standard.object(forKey: "xnonce")
    else { return }
    
    let dic = ["2": "B", "1": "A", "3": "C"]
    let encoder = JSONEncoder()
    if let jsonData = try? encoder.encode(dic) {
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }
    
    GatewayConnection.validateTicketing(url: url, parameters: nil) { resultStr in
      print(resultStr)
    }
  }
}
