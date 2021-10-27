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
//  SavedPDF.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 23.08.2021.
//  
        

import UIKit
import PDFKit

public class SavedPDF: Codable {
  
  public var identifier: String
  public var fileName: String
  public var pdfData: Data?
  public var date: Date

  var pdf: PDFDocument? {
    get { return PDFDocument(data: pdfData ?? Data()) }
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
         pdfData,
         date
  }
  
  // Init with custom fields
  public init( fileName: String, pdfUrl: URL) {
    self.identifier = UUID().uuidString
    self.fileName = fileName
    self.pdfData = try? Data(contentsOf: pdfUrl, options: .mappedIfSafe)
    self.date = Date()
  }
  
  // Init Rule from JSON Data
  required public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    identifier = try container.decode(String.self, forKey: .identifier)
    fileName = try container.decode(String.self, forKey: .fileName)
    pdfData = try container.decode(Data.self, forKey: .pdfData)
    date = try container.decode(Date.self, forKey: .date)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(identifier, forKey: .identifier)
    try container.encode(fileName, forKey: .fileName)
    try container.encode(pdfData, forKey: .pdfData)
    try container.encode(date, forKey: .date)
  }
}
