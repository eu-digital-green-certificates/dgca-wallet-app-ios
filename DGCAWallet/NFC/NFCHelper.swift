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
//  NFCHelper.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 23.08.2021.
//  
        

import Foundation
import CoreNFC
import DGCCoreLibrary

protocol NFCCommunicating: AnyObject {
    func onNFCResult(_ result: Bool, message: String)
}

class NFCHelper: NSObject, NFCNDEFReaderSessionDelegate {
    weak var delegate: NFCCommunicating?
    
    func restartSession() {
        let session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session.begin()
    }
    
    // MARK: NFCNDEFReaderSessionDelegate
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        delegate?.onNFCResult(false, message: error.localizedDescription)
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        for message in messages {
            for record in message.records {
                DGCLogger.logInfo("NFC_READ: RECORD IDENTIFIER: \(record.identifier)")
                DGCLogger.logInfo("NFC_READ: RECORD payload: \(record.payload)")
                DGCLogger.logInfo("NFC_READ: RECORD type: \(record.type)")
                DGCLogger.logInfo("NFC_READ: RECORD typeNameFormat: \(record.typeNameFormat)")
                
                if var resultString = String(data: record.payload, encoding: .utf8) {
                    if let hceRange = resultString.range(of: "HC1:") {
                        resultString.removeSubrange(resultString.startIndex..<hceRange.lowerBound)
                    }
                    delegate?.onNFCResult(true, message: resultString)
                } else {
                    delegate?.onNFCResult(false, message: "don't found any info")
                }
            }
        }
    }
}
