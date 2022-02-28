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
//  LicenseController.swift
//  DGCAWallet
//  
//  Created by Paul Ballmann on 19.05.21.
//

import UIKit
import SwiftyJSON
import WebKit

class LicenseController: UIViewController, WKNavigationDelegate {
  @IBOutlet fileprivate weak var packageNameLabel: UILabel!
  @IBOutlet fileprivate weak var licenseWebView: WKWebView!
  @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!

  var licenseObject: JSON = []

  override func viewDidLoad() {
    super.viewDidLoad()
    packageNameLabel.text = licenseObject["name"].string
    licenseWebView.isUserInteractionEnabled = false
    licenseWebView.navigationDelegate = self
    if #available(iOS 13.0, *) {
      activityIndicator.style = .medium
    } else {
      activityIndicator.style = .gray
    }

    if let licenseUrl = licenseObject["licenseUrl"].string {
      loadWebView(licenseUrl)
    }
  }

  @IBAction func doneAction(_ sender: Any) {
    self.dismiss(animated: true)
  }

  func loadWebView(_ packageLink: String) {
    DispatchQueue.main.async { [weak self] in
      let request = URLRequest(url: URL(string: packageLink)!)
      self?.licenseWebView?.load(request)
    }

    activityIndicator.startAnimating()
    licenseWebView.navigationDelegate = self
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    activityIndicator.stopAnimating()
  }

  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    activityIndicator.stopAnimating()
  }
}
