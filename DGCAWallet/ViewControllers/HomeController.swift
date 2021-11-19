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
  let showMainList = "showMainList"
  
  @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  var downloadedDataHasExpired: Bool {
    return DataCenter.lastFetch.timeIntervalSinceNow < -SharedConstants.expiredDataInterval
  }
  
  var appWasRunWithOlderVersion: Bool {
    return DataCenter.lastLaunchedAppVersion != DataCenter.appVersion
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    CoreManager.shared.config = HCertConfig(prefetchAllCodes: true, checkSignatures: false, debugPrintJsonErrors: true)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    DataCenter.initializeLocalData {[unowned self] in
      DispatchQueue.main.async {
        self.downloadedDataHasExpired || self.appWasRunWithOlderVersion ? self.reloadStorageData() : self.initializeAllStorageData()
      }
    }
  }
  
  func initializeAllStorageData() {
    self.activityIndicator.startAnimating()
    DataCenter.initializeAllStorageData { [unowned self] in
      DispatchQueue.main.async {
        self.activityIndicator.stopAnimating()
        self.loadComplete()
      }
    }
  }
  
  func reloadStorageData() {
    self.activityIndicator.startAnimating()
    DataCenter.reloadStorageData { [unowned self] in
      DispatchQueue.main.async {
        self.activityIndicator.stopAnimating()
        self.loadComplete()
      }
    }
  }
  
  private func loadComplete() {
    let renderer = UIGraphicsImageRenderer(size: self.view.bounds.size)
    SecureBackground.image = renderer.image { rendererContext in
      self.view.layer.render(in: rendererContext.cgContext)
    }
    
    if DataCenter.localDataManager.versionedConfig["outdated"].bool == true {
      showAlert(title: l10n("Update available"), subtitle: l10n("This version of the app is out of date."))
      return
    }
    SecureBackground.checkId(from: self) { success in
      DispatchQueue.main.async { [weak self] in
        if success {
          self?.performSegue(withIdentifier: self!.showMainList, sender: nil)
        } else {
          self?.loadComplete()
        }
      }
    }
  }
}
