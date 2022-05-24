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
//  InfoCell.swift
//  DGCAWallet
//
//  Created by Yannick Spreen on 4/20/21.
//

import UIKit
import DGCCoreLibrary

class InfoCell: UITableViewCell {
    
    @IBOutlet fileprivate weak var headerLabel: UILabel!
    @IBOutlet fileprivate weak var contentLabel: UILabel!

    func setupCell(_ info: InfoSection) {
        headerLabel?.text = info.header
        contentLabel?.text = info.content
        let fontSize = contentLabel.font.pointSize
        let fontWeight = contentLabel.font.weight
        switch info.style {
        case .fixedWidthFont:
            if #available(iOS 13.0, *) {
                contentLabel.font = .monospacedSystemFont(ofSize: fontSize, weight: fontWeight)
            } else {
                contentLabel.font = .monospacedDigitSystemFont(ofSize: fontSize, weight: fontWeight)
            }
        default:
            contentLabel.font = .systemFont(ofSize: fontSize, weight: fontWeight)
        }
    }
}
