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
//  Wallet.swift
//  DGCAWallet
//  
//  Created by Igor Khomiak on 11/9/21.
//  
        

import UIKit
import SwiftDGC

class Wallet {
    static let shared = Wallet()
    
  var selectedCountryCode: String? {
    return self.selectedCounty?.code
  }

  //Selected country code
  var selectedCounty: CountryModel? {
    set {
      let userDefaults = UserDefaults.standard
      do {
        try userDefaults.setObject(newValue, forKey: SharedConstants.userDefaultsCountryKey)
      } catch {
        print(error.localizedDescription)
      }
    }
    get {
      let userDefaults = UserDefaults.standard
      do {
        let selected = try userDefaults.getObject(forKey: SharedConstants.userDefaultsCountryKey, castTo: CountryModel.self)
        return selected
      } catch {
        print(error.localizedDescription)
        return nil
      }
    }
  }

}
