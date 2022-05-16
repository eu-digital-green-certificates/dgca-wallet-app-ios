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
//  SceneDelegate.swift
//  DGCAWallet
//
//  Created by Yannick Spreen on 4/8/21.
//

import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow? {
        didSet {
            let style = UITraitCollection.current.userInterfaceStyle
            window?.overrideUserInterfaceStyle = style
        }
    }
    
    var isNFCFunctionality = false
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            self.window = UIWindow(windowScene: windowScene)
            self.window?.rootViewController = UIStoryboard(name: "Main", bundle: .main).instantiateInitialViewController()
            self.window?.makeKeyAndVisible()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        if !isNFCFunctionality {
            SecureBackground.shared.enable()
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        isNFCFunctionality = false
        let style = UITraitCollection.current.userInterfaceStyle
        let mySceneDelegate = scene.delegate as? SceneDelegate
        let window = mySceneDelegate?.window
        window?.overrideUserInterfaceStyle = style

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
