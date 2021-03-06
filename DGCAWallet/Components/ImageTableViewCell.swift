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
//  ImageTableViewCell.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 25.08.2021.
//  
        

import UIKit

class ImageTableViewCell: UITableViewCell {
  @IBOutlet fileprivate weak var imagePreviewView: UIImageView!
  @IBOutlet fileprivate weak var nameLabel: UILabel!
  @IBOutlet fileprivate weak var timeLabel: UILabel!

  private var savedImage: SavedImage? {
    didSet {
      setupView()
    }
  }
    
  func setImage(image: SavedImage) {
    savedImage = image
  }
  
  private func setupView() {
    guard let savedImage = savedImage else {
      imagePreviewView.image = nil
      nameLabel.text = ""
      return
    }
    imagePreviewView.image = savedImage.image
    nameLabel.text = savedImage.fileName
    timeLabel.text = savedImage.dateString
  }
  
  override func prepareForReuse() {
      savedImage = nil
  }
}
