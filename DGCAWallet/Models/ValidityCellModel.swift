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
//  ValidityCellModel.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 08.07.2021.
//  
        

import Foundation

enum ValidityCellModelType: Int {
  case titleAndDescription
  case countryAndTimeSelection
}

public final class ValidityCellModel {
  var cellType: ValidityCellModelType = .titleAndDescription
  var title: String?
  var description: String?
  var needChangeTitleFont: Bool = false
  
  init(cellType: ValidityCellModelType = .titleAndDescription, title: String? = nil, description: String? = nil, needChangeTitleFont: Bool = false) {
    self.needChangeTitleFont = needChangeTitleFont
    self.cellType = cellType
    self.title = title
    self.description = description
  }
}
