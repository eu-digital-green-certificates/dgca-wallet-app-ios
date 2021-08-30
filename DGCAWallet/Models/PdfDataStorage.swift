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
//  PdfDataStorage.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 23.08.2021.
//  
        

import Foundation

import SwiftDGC

struct PdfDataStorage: Codable {
  static var sharedInstance = PdfDataStorage()
  static let storage = SecureStorage<PdfDataStorage>(fileName: "pdfs_secure")

  var pdfs = [SavedPDF]()

  mutating func add(savedPdf: SavedPDF) {
    let list = pdfs
    if list.contains(where: { pdf in
      pdf.identifier == savedPdf.identifier
    }) {
      return
    }
    pdfs.append(savedPdf)
    save()
  }

  public func save() {
    Self.storage.save(self)
  }

  public mutating func deletePdfWith(identifier: String) {
    self.pdfs = self.pdfs.filter { $0.identifier != identifier }
    save()
  }

  public func isPdfExistWith(identifier: String) -> Bool {
    let list = pdfs
    return list.contains(where: { pdf in
      pdf.identifier == identifier
    })
  }
  static func initialize(completion: @escaping () -> Void) {
    storage.loadOverride(fallback: PdfDataStorage.sharedInstance) { success in
      guard let result = success else {
        return
      }
      let format = l10n("log.pdfs")
      print(String.localizedStringWithFormat(format, result.pdfs.count))
      PdfDataStorage.sharedInstance = result
      completion()
    }
  }
}
