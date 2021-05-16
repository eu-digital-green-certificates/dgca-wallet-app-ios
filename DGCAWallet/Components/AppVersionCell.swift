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
//  AppVersionCell.swift
//  DGCAWallet
//  
//  Created by Paul Ballmann on 14.05.21.
//  

#if os(iOS)
import UIKit
import SwiftDGC

class AppVersionCell: UITableViewCell {
  @IBOutlet weak var versionLabel: UILabel!

  override func layoutSubviews() {
    super.layoutSubviews()

    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    let format = l10n("app-version")
    versionLabel.text = String(format: format, version ?? "?")

    for subview in subviews {
      if
        subview != contentView,
        abs(subview.frame.width - frame.width) <= 0.1,
        subview.frame.height < 2
      {
        subview.alpha = 0
      }
    }
  }
}
#endif
