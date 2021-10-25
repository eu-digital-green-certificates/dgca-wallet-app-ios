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
//  ImageDataStorage.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 23.08.2021.
//  
        

import Foundation
import SwiftDGC

class ImageDataStorage: Codable {
  static var sharedInstance = ImageDataStorage()
  static let storage = SecureStorage<ImageDataStorage>(fileName: "images_secure")

  var images = [SavedImage]()

  func add(savedImage: SavedImage, completion: ((Bool) -> Void)? = nil) {
    let list = images
    if list.contains(where: { $0.identifier == savedImage.identifier }) {
      return
    }
    images.append(savedImage)
    Self.storage.save(self, completion: completion)
  }

  func deleteImage(with identifier: String, completion: ((Bool) -> Void)? = nil) {
    self.images = self.images.filter { $0.identifier != identifier }
    Self.storage.save(self, completion: completion)
  }

  func isImageExistWith(identifier: String) -> Bool {
    let list = images
    return list.contains(where: { image in
      image.identifier == identifier
    })
  }
  
  static func initialize(completion: @escaping () -> Void) {
    storage.loadOverride(fallback: ImageDataStorage.sharedInstance) { success in
      guard let result = success else { return }
      
      let format = l10n("log.images")
      print(String.localizedStringWithFormat(format, result.images.count))
      ImageDataStorage.sharedInstance = result
      completion()
    }
  }
}
