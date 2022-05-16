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

protocol SecureAuthorising {
    func tryAgainAuthentication()
}

class SecureBackground {
    static var shared = SecureBackground()
    
    var paused = false
    
    private var activation = Date()
    private var secureView: UIView?

    var shouldAuthenticate: Bool {
        return Date() > activation.addingTimeInterval(60.0)
    }
    
    func enable() {
        self.disable()
        if let authenticationController = UIStoryboard(name: "Authentication", bundle: nil).instantiateInitialViewController() as? LocalSceneAuthenticationController {
            authenticationController.delegate = self
            authenticationController.loadView()
            authenticationController.setupInterface()
            if let view = authenticationController.view {
                view.frame = UIScreen.main.bounds
                UIApplication.shared.windows.first?.addSubview(view)
                self.secureView = view
            }
        }
        self.activation = Date()
    }

    func disable() {
        DispatchQueue.main.async {
            self.secureView?.removeFromSuperview()
            self.secureView = nil
        }
    }
}

extension SecureBackground: SecureAuthorising {
    func tryAgainAuthentication() {
        self.authenticationWithTouchID { result, error in
            if result {
                self.disable()
            }
        }
    }
}

extension SecureBackground {
    func authenticationWithTouchID(completion: @escaping AuthenticationCompletionHandler) {
        let localAuthenticationContext = LAContext()
        localAuthenticationContext.localizedFallbackTitle = "Use Passcode".localized
        
        var authError: NSError?
        let reasonString = "To access the secure data".localized

        if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString) { [unowned self] success, evaluateError in
                
                DispatchQueue.main.async {
                    if success {
                        completion(true, nil)
                        
                    } else {
                        guard let error = evaluateError else { return }

                      if error._code == LAError.biometryNotAvailable.rawValue {
                        completion(true, nil)
                      } else {
                        let messageStr = self.evaluateAuthenticationPolicyMessageForLA(errorCode: error._code)

                        self.showAlert(withTitle: "You did not authenticate successfully".localized, message: messageStr)
                        completion(false, error)
                      }
                    }
                }
            }
        } else {
          completion(true, nil)
        }
    }

    func evaluatePolicyFailErrorMessageForLA(errorCode: Int) -> String {
        var message = ""
        if #available(iOS 11.0, macOS 10.13, *) {
            switch errorCode {
                case LAError.biometryNotAvailable.rawValue:
                message = "Authentication could not start because the device does not support biometric authentication.".localized
                
                case LAError.biometryLockout.rawValue:
                    message = "Authentication could not continue because the user has been locked out of biometric authentication, due to failing authentication too many times.".localized
                
                case LAError.biometryNotEnrolled.rawValue:
                    message = "Authentication could not start because the user has not enrolled in biometric authentication.".localized
                
                default:
                    message = "Did not find error code on LAError object".localized
            }
            
        } else {
            switch errorCode {
                case LAError.touchIDLockout.rawValue:
                    message = "Too many failed attempts.".localized
                
                case LAError.touchIDNotAvailable.rawValue:
                    message = "TouchID is not available on the device".localized
                
                case LAError.touchIDNotEnrolled.rawValue:
                    message = "TouchID is not enrolled on the device".localized
                
                default:
                    message = "Did not find error code on LAError object".localized
            }
        }
        
        return message
    }
    
    func evaluateAuthenticationPolicyMessageForLA(errorCode: Int) -> String {
        let message: String
        switch errorCode {
            
        case LAError.authenticationFailed.rawValue:
            message = "The user failed to provide valid credentials".localized
            
        case LAError.appCancel.rawValue:
            message = "Authentication was cancelled by application".localized
            
        case LAError.invalidContext.rawValue:
            message = "The context is invalid".localized
            
        case LAError.notInteractive.rawValue:
            message = "Not interactive"
            
        case LAError.passcodeNotSet.rawValue:
            message = "Passcode is not set on the device".localized
            
        case LAError.systemCancel.rawValue:
            message = "Authentication was cancelled by the system".localized
            
        case LAError.userCancel.rawValue:
            message = "The user did cancel".localized
            
        case LAError.userFallback.rawValue:
            message = "The user chose to use the fallback".localized
            
        default:
            message = evaluatePolicyFailErrorMessageForLA(errorCode: errorCode)
        }
        
        return message
    }
    
    private func showAlert(withTitle title: String, message: String?) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK".localized, style: .default))
            UIViewController.topMostViewController()?.present(alertController, animated: true)
        }
    }
}
