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
//  ExtendedValidityCell.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 08.07.2021.
//  
        

import UIKit
import DGCVerificationCenter
import DGCCoreLibrary

typealias OnDateChangedHandler = (Date) -> Void
typealias OnCountryChangedHandler = (String?) -> Void

class ExtendedValidityCell: UITableViewCell {
    private enum Constants {
      static let userDefaultsCountryKey = "UDWalletCountryKey"
    }

    @IBOutlet fileprivate weak var destinationLabel: UILabel!
    @IBOutlet fileprivate weak var countryPicker: UIPickerView!
    @IBOutlet fileprivate weak var dateLabel: UILabel!
    @IBOutlet fileprivate weak var datePicker: UIDatePicker!
    
    private var countryItems: [CountryModel] = []
    var dataHandler: OnDateChangedHandler?
    var countryHandler: OnCountryChangedHandler?

    private var selectedCounty: CountryModel? {
        set {
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(newValue)
                UserDefaults.standard.set(data, forKey: Constants.userDefaultsCountryKey)
            } catch {
                DGCLogger.logError(error)
            }
        }
        get {
            if let data = UserDefaults.standard.data(forKey: Constants.userDefaultsCountryKey) {
                let decoder = JSONDecoder()
                do {
                    let object = try decoder.decode(CountryModel.self, from: data)
                    return object
                } catch {
                    DGCLogger.logError(error)
                }
            }
            return nil
        }
    }

    func setupView() {
        destinationLabel.text = "Your destination country".localized
        dateLabel.text = "Check the date".localized
        datePicker.minimumDate = Date()
        if #available(iOS 13.4, *) {
          datePicker.preferredDatePickerStyle = .wheels
        } else {
          // Fallback on earlier versions
        }
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        setListOfRuleCounties(list: DGCVerificationCenter.countryCodes)
    }
}

extension ExtendedValidityCell {
    @objc func dateChanged(_ sender: UIDatePicker) {
      dataHandler?(sender.date)
    }
}

extension ExtendedValidityCell: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
      return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return countryItems.isEmpty ? 1 : countryItems.count
    }
      
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if countryItems.count == 0 {
            return "Country codes list empty".localized
        } else {
            return countryItems[row].name
        }
    }
      
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
      self.selectedCounty = countryItems[row]
      countryHandler?(self.selectedCounty?.code)
    }
}

extension ExtendedValidityCell {
    func setListOfRuleCounties(list: [CountryModel]) {
        self.countryItems = list
        self.countryPicker.reloadAllComponents()
        guard self.countryItems.count > 0 else { return }
          
        if let selected = self.selectedCounty,
           let indexOfCountry = self.countryItems.firstIndex(where: {$0.code == selected.code}) {
          countryPicker.selectRow(indexOfCountry, inComponent: 0, animated: false)
          countryHandler?(selected.code)
        } else {
          self.selectedCounty = self.countryItems.first
          countryPicker.selectRow(0, inComponent: 0, animated: false)
          countryHandler?(self.selectedCounty?.code)
        }
    }
}
