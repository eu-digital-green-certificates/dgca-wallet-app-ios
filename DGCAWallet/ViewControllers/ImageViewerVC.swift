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
//  ImageViewerVC.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 25.08.2021.
//  
        

import UIKit

class ImageViewerVC: UIViewController {

  @IBOutlet weak var closeButton: UIButton!
  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var shareButton: UIButton!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var scrollView: UIScrollView!
  var savedImage: SavedImage? {
    didSet {
      setupView()
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
  }

  func setImage( image: SavedImage? = nil) {
    savedImage = image
  }

  private func setupView() {
    guard let savedImage = savedImage, let scrollView = scrollView, let imageView = imageView else {
      return
    }
    scrollView.backgroundColor = .lightGray
    imageView.image = savedImage.image
    scrollView.delegate = self
    scrollView.minimumZoomScale = 1.0
    scrollView.maximumZoomScale = 5.0
    scrollView.zoomScale = 1.0
    self.navigationItem.title = savedImage.fileName
  }
    
  @IBAction func shareAction(_ sender: Any) {
    guard let savedImage = savedImage else {
      return
    }
    let imageToShare = [ savedImage.image ]
    let activityViewController = UIActivityViewController(activityItems: imageToShare as [Any],
                                                          applicationActivities: nil)
    activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
    self.present(activityViewController, animated: true, completion: nil)

  }
  
  @IBAction func backAction(_ sender: Any) {
    self.dismiss(animated: true)
  }
  
  @IBAction func closeAction(_ sender: Any) {
    self.dismiss(animated: true)
  }
}

extension ImageViewerVC: UIScrollViewDelegate {
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
       imageView
  }
}
