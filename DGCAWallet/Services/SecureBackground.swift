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


import Foundation
import UIKit
import LocalAuthentication
import SwiftDGC

struct SecureBackground {
  static var imageView: UIImageView?
  public static var image: UIImage?

  public static func enable() {
    guard !paused else {
      return
    }
    disable()
    guard let image = image else {
      return
    }
    let imageView = UIImageView(image: image)
    UIApplication.shared.windows[0].addSubview(imageView)
    Self.imageView = imageView
    Self.activation = Date()
  }

  public static func disable() {
    if imageView != nil {
      if activation.timeIntervalSinceNow < -1 {
        (UIApplication.shared.windows[0].rootViewController as? UINavigationController)?.popToRootViewController(animated: false)
      }
      imageView?.removeFromSuperview()
      imageView = nil
    }
  }

  static var paused = false
  static var activation = Date()
  public static func checkId(completion: ((Bool) -> Void)?) {
    guard !paused else {
      return
    }
    paused = true
    let context = LAContext()
    context.localizedCancelTitle = l10n("auth.later")
    let reason = l10n("auth.confirm")
    var error: NSError?
    guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
      paused = false
      completion?(true)
      return
    }
    context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason ) { success, error in
      if success {
        // Move to the main thread because a state update triggers UI changes.
        DispatchQueue.main.async {
          paused = false
          completion?(true)
        }
      } else {
        paused = false
        completion?(false)
      }
    }
  }
}
