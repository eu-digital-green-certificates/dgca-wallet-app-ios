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
//  SecureBackground.swift
//  DGCAWallet
//  
//  Created by Yannick Spreen on 4/27/21.
//  

import UIKit
import LocalAuthentication
import DGCCoreLibrary

struct SecureBackground {
    static var imageView: UIImageView?
    public static var image: UIImage?

    public static func enable() {
        guard !paused else { return }
        
        disable()
        // return
        guard let image = image else { return }
        let imageView = UIImageView(image: image)
        UIApplication.shared.windows.first?.addSubview(imageView)
        Self.imageView = imageView
        Self.activation = Date()
    }

    public static func disable() {
        if imageView != nil {
          if activation.timeIntervalSinceNow < -1 {
              // (UIApplication.shared.windows.first?.rootViewController as? UINavigationController)?.popToRootViewController(animated: false)
          }
          imageView?.removeFromSuperview()
          imageView = nil
        }
    }

    static var paused = false
    static var activation = Date()

    public static func checkId(from controller: UIViewController? = nil, completion: ((Bool) -> Void)?) {
        guard !paused else { return }
          
        paused = true
        let context = LAContext()
        context.localizedCancelTitle = "Try Later".localized
        let reason = "Could not verify device ownership".localized
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason ) { success, err in
            if success {
                paused = false
                completion?(true)
            } else {
                paused = false
                if controller == nil || (err as? LAError)?.code != LAError.passcodeNotSet {
                    completion?(false)
                    return
                }
                  
                DispatchQueue.main.async {
                    controller?.showAlert(title: "Could not verify device ownership".localized,
                        subtitle: "Please try setting a passcode for this device before opening the app.".localized) { _ in
                      completion?(false)
                    }
                }
            }
        }
    }
}
