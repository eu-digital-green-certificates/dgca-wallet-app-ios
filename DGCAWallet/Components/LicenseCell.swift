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
//  LicenseCell.swift
//  DGCAWallet
//  
//  Created by Paul Ballmann on 19.05.21.
//

import UIKit
import SwiftyJSON

class LicenseCell: UITableViewCell {
    
    @IBOutlet fileprivate weak var cellLabel: UILabel!

    var licenseObject: JSON = []

    func drawLabel(_ licenseObject: JSON) {
        self.licenseObject = licenseObject
        self.cellLabel.text = licenseObject["name"].string
    }
}
