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
//  SavedImage.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 23.08.2021.
//  
        

import Foundation
import UIKit

public class SavedImage: Codable {
  
  public var identifier: String
  public var fileName: String
  public var imageString: String
  public var date: Date

  var image: UIImage? {
    get { return imageString.convertBase64StringToImage() }
  }
  
  var dateString: String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .long
    dateFormatter.timeStyle = .short
    return dateFormatter.string(from: date)
  }
  
  enum CodingKeys: String, CodingKey {
    case identifier,
         fileName,
         imageString,
         date
  }
  
  // Init with custom fields
  public init( fileName: String, image: UIImage) {
    self.identifier = UUID().uuidString
    self.fileName = fileName
    self.imageString = image.convertImageToBase64String()
    self.date = Date()
  }
  
  // Init Rule from JSON Data
  required public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    identifier = try container.decode(String.self, forKey: .identifier)
    fileName = try container.decode(String.self, forKey: .fileName)
    imageString = try container.decode(String.self, forKey: .imageString)
    date = try container.decode(Date.self, forKey: .date)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(identifier, forKey: .identifier)
    try container.encode(fileName, forKey: .fileName)
    try container.encode(imageString, forKey: .imageString)
    try container.encode(date, forKey: .date)
  }
}
