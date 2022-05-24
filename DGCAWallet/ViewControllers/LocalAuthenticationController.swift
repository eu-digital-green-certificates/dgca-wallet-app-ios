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
//  LocalAuthenticationController.swift
//  DGCAWallet
//  
//  Created by Igor Khomiak on 29.04.2022.
//  


import UIKit
import LocalAuthentication

class LocalAuthenticationController: UIViewController {

    let showHomeLoadingData = "showHomeLoadingData"
    
    @IBOutlet fileprivate weak var appNameLabel: UILabel!
    @IBOutlet fileprivate weak var messageLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        appNameLabel.text = "Wallet App".localized
        messageLabel.text = "Please authenticate to access the secure data.".localized
#if targetEnvironment(simulator)
        self.performSegue(withIdentifier: self.showHomeLoadingData, sender: nil)
#else
        authenticationWithTouchID()
#endif
    }
}

extension LocalAuthenticationController {
    
    func authenticationWithTouchID() {
        SecureBackground.shared.authenticationWithTouchID { success, error in
            guard let error = error else {
                self.performSegue(withIdentifier: self.showHomeLoadingData, sender: nil)
                return
            }

            let messageStr = self.evaluateAuthenticationPolicyMessageForLA(errorCode: error._code)
            self.showAlert(withTitle: "You did not authenticate successfully".localized, message: messageStr)
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
        
        return message;
    }
    
    func evaluateAuthenticationPolicyMessageForLA(errorCode: Int) -> String {
        var message = ""
        
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
            self.present(alertController, animated: true)
        }
    }
}
