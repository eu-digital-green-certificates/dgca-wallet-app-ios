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
    //  AppDelegate.swift
    //  DGCAWallet
    //
    //  Created by Yannick Spreen on 4/8/21.
    //

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var isNFCFunctionality = false
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if #available(iOS 13, *) {
            return true
        } else {
            self.window = UIWindow()
            self.window?.rootViewController = UIStoryboard(name: "Main", bundle: .main).instantiateInitialViewController()
            self.window?.makeKeyAndVisible()
            return true
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        if !isNFCFunctionality {
            SecureBackground.shared.enable()
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        isNFCFunctionality = false
#if targetEnvironment(simulator)
        SecureBackground.shared.disable()
#else
        if !SecureBackground.shared.shouldAuthenticate {
            SecureBackground.shared.disable()
        } else {
            SecureBackground.shared.authenticationWithTouchID { rezult, error in
                if rezult {
                    SecureBackground.shared.disable()
                }
            }
        }
#endif
    }
}
