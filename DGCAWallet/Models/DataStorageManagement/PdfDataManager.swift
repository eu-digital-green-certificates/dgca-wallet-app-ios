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
//  PdfDataManager.swift
//  DGCAVerifier
//  
//  Created by Igor Khomiak on 22.06.2021.
//  
import Foundation
import SwiftDGC

class PdfDataManager {
  lazy var pdfData = PdfDataStorage()
  lazy var storage = SecureStorage<PdfDataStorage>(fileName: SharedConstants.pdfStorageName)
  
  func add(savedPdf: SavedPDF, completion: ((Bool) -> Void)? = nil) {
    if !pdfData.pdfs.contains(where: { $0.identifier == savedPdf.identifier }) {
      pdfData.pdfs.append(savedPdf)
      storage.save(pdfData, completion: completion)
    }
  }
  
  func deletePDF(with identifier: String, completion: ((Bool) -> Void)? = nil) {
    let pdfs = pdfData.pdfs.filter { $0.identifier != identifier }
    pdfData.pdfs = pdfs
    storage.save(pdfData, completion: completion)
  }

  func isPdfExistWith(identifier: String) -> Bool {
    return pdfData.pdfs.contains(where: { $0.identifier == identifier })
  }
  
  func save(completion: ((Bool) -> Void)? = nil) {
    storage.save(pdfData, completion: completion)
  }

  func initialize(completion: @escaping CompletionHandler) {
    storage.loadOverride(fallback: pdfData) { [unowned self] value in
      guard let result = value else {
        completion()
        return
      }
      DGCLogger.logInfo(String(format: "Loaded %d pdf files", result.pdfs.count))
      self.pdfData = result
      self.save()
      completion()
    }
  }
}
