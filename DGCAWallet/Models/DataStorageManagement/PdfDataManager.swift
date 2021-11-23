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
  var localData: PdfDataStorage = PdfDataStorage()
  lazy var storage = SecureStorage<PdfDataStorage>(fileName: SharedConstants.pdfStorageName)
  
  func add(savedPdf: SavedPDF, completion: @escaping DataCompletionHandler) {
    if !localData.pdfs.contains(where: { $0.identifier == savedPdf.identifier }) {
      localData.pdfs.append(savedPdf)
      storage.save(localData, completion: completion)
    } else {
      completion(.success(true))
    }
  }
  
  func deletePDF(with identifier: String, completion: @escaping DataCompletionHandler) {
    let pdfs = localData.pdfs.filter { $0.identifier != identifier }
    localData.pdfs = pdfs
    storage.save(localData, completion: completion)
  }

  func isPdfExistWith(identifier: String) -> Bool {
    return localData.pdfs.contains(where: { $0.identifier == identifier })
  }
  
  func save(completion: @escaping DataCompletionHandler) {
    storage.save(localData, completion: completion)
  }

  func loadLocallyStoredData(completion: @escaping DataCompletionHandler) {
    storage.loadStoredData(fallback: localData) { [unowned self] data in
      guard let result = data else {
        completion(.failure(DataOperationError.noInputData))
        return
      }
      DGCLogger.logInfo(String(format: "Loaded %d pdf files", result.pdfs.count))
      self.localData = result
      completion(.success(true))
    }
  }
}
