//
/*-
 * ---license-start
 * eu-digital-green-certificates / dgca-verifier-app-ios
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
//  ImageDataManager.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 22.06.2021.
//  
import Foundation
import SwiftDGC
import SwiftyJSON

class ImageDataManager {
  lazy var imageData: ImageDataStorage = ImageDataStorage()
  lazy var storage = SecureStorage<ImageDataStorage>(fileName: SharedConstants.imageStorageName)
  
  func add(savedImage: SavedImage, completion: ((Bool) -> Void)? = nil) {
    if !imageData.images.contains(where: { $0.identifier == savedImage.identifier }) {
      imageData.images.append(savedImage)
      storage.save(imageData, completion: completion)
    }
  }
  
  func deleteImage(with identifier: String, completion: ((Bool) -> Void)? = nil) {
    let images = imageData.images.filter { $0.identifier != identifier }
    imageData.images = images
    storage.save(imageData, completion: completion)
  }

  func isImageExistWith(identifier: String) -> Bool {
    return imageData.images.contains(where: { $0.identifier == identifier })
  }
  
  func save(completion: ((Bool) -> Void)? = nil) {
    storage.save(imageData, completion: completion)
  }

  func initialize(completion: @escaping () -> Void) {
    storage.loadOverride(fallback: imageData) { [unowned self] value in
      guard let result = value else {
        completion()
        return
      }
      DGCLogger.logInfo(String(format: "Loaded %@ images", result.images.count))
      self.imageData = result
      self.save()
      completion()
    }
  }
}
