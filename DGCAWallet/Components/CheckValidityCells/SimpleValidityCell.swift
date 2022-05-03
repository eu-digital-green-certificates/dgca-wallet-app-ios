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
//  SimpleValidityCell.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 08.07.2021.
//  
        

import UIKit
import DCCInspection

class SimpleValidityCell: UITableViewCell {
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var descriptionLabel: UILabel!
  
    private weak var cellModel: ValidityCellModel? {
        didSet {
            self.setupView()
        }
    }

    override func prepareForReuse() {
        setInitialStrings()
    }

    func setupCell(with model: ValidityCellModel) {
        self.cellModel = model
    }

    private func setInitialStrings() {
        titleLabel.text = ""
        descriptionLabel.text = ""
    }

    private func setupView() {
        guard let cellModel = cellModel else {
            setInitialStrings()
            return
        }
        
        titleLabel.text = cellModel.title
        descriptionLabel.text = cellModel.description
        
        let sizeValue: CGFloat = cellModel.needChangeTitleFont ? 24.0 : 14.0
        titleLabel.font = UIFont.boldSystemFont(ofSize: sizeValue)
    }
}
