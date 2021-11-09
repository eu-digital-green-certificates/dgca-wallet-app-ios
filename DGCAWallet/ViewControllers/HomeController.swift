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
//  HomeController.swift
//  DGCAWallet
//  
//  Created by Yannick Spreen on 4/25/21.
//  

import UIKit
import SwiftDGC

class HomeController: UIViewController {
    
    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!

    override var preferredStatusBarStyle: UIStatusBarStyle {
      return .lightContent
    }

  override func viewDidLoad() {
    super.viewDidLoad()

    HCert.config.prefetchAllCodes = true
    HCert.config.checkSignatures = false
        
    performServicesInitialization()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    if loaded {
      checkId()
    }
  }

  var loaded = false
    
  private func performServicesInitialization() {
    self.activityIndicator.startAnimating()
    RulesDataStorage.initialize {
      GatewayConnection.rulesList { _ in
        CertLogicEngineManager.sharedInstance.setRules(ruleList: RulesDataStorage.sharedInstance.rules)
        GatewayConnection.loadRulesFromServer { _ in
          CertLogicEngineManager.sharedInstance.setRules(ruleList: RulesDataStorage.sharedInstance.rules)
          ValueSetsDataStorage.initialize {
            GatewayConnection.valueSetsList { _ in
              GatewayConnection.loadValueSetsFromServer { _ in
                GatewayConnection.countryList { _ in
                    LocalData.initialize {
                      DispatchQueue.main.async { [unowned self] in
                        self.activityIndicator.stopAnimating()
                        let renderer = UIGraphicsImageRenderer(size: self.view.bounds.size)
                        SecureBackground.image = renderer.image { rendererContext in
                          self.view.layer.render(in: rendererContext.cgContext)
                        }
                        self.loaded = true
                        self.checkId()
                      }
                    } // end localData init
                }
              }
            }
          }
        }
      }
    } // End of Rules
  }

  func checkId() {
    if LocalData.sharedInstance.versionedConfig["outdated"].bool == true {
      showAlert(title: l10n("info.outdated"), subtitle: l10n("info.outdated.body"))
      return
    }
    SecureBackground.checkId(from: self) { success in
      DispatchQueue.main.async { [weak self] in
        if success {
          self?.performSegue(withIdentifier: "list", sender: self)
        } else {
          self?.checkId()
        }
      }
    }
  }
}
