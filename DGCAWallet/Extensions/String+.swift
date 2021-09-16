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
//  String+.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 23.08.2021.
//  
        

import Foundation
import UIKit

extension String {
  func convertBase64StringToImage () -> UIImage? {
    guard let imageData = Data.init(base64Encoded: self, options: .init(rawValue: 0)) else { return nil }
      let image = UIImage(data: imageData)
      return image
  }
}
