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
//  UIImage+.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 20.08.2021.
//  
        

import UIKit

extension UIImage {
  func qrCodeString() -> String? {
    var qrAsString = ""
    guard let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                                    context: nil,
                                    options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]),
          let ciImage = CIImage(image: self),
          let features = detector.features(in: ciImage) as? [CIQRCodeFeature] else {
      return qrAsString
    }
    for feature in features {
      guard let indeedMessageString = feature.messageString else {
        continue
      }
      qrAsString += indeedMessageString
    }
    return qrAsString.isEmpty ? nil : qrAsString
  }
  
  func convertImageToBase64String () -> String {
      return self.jpegData(compressionQuality: 1)?.base64EncodedString() ?? ""
  }
}
