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
//  TicketingAcceptanceController.swift
//  DGCAWallet
//  
//  Created by Alexandr Chernyy on 16.09.2021.
//  


import UIKit
import SwiftDGC
import CryptoSwift

class TicketingAcceptanceController: UIViewController {
  private enum Segues {
    static let showValidationResult = "showValidationResult"
  }

  @IBOutlet fileprivate weak var certificateTitle: UILabel!
  @IBOutlet fileprivate weak var validToLabel: UILabel!
  @IBOutlet fileprivate weak var consetsLabel: UILabel!
  @IBOutlet fileprivate weak var infoLabel: UILabel!
  @IBOutlet fileprivate weak var cancelButton: UIButton!
  @IBOutlet fileprivate weak var grandButton: UIButton!
  @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!
 
  private var ticketingAcceptance: TicketingAcceptance?
  private var certificate: HCert?
  private var loading = false

  override func viewDidLoad() {
    super.viewDidLoad()
    setupView(isValidation: true)
  }
  
  private func startActivity() {
    loading = true
    activityIndicator.startAnimating()
    cancelButton.isEnabled = false
    grandButton.isEnabled = false
  }
 
  private func stopActivity() {
    loading = false
    activityIndicator.stopAnimating()
    cancelButton.isEnabled = true
    grandButton.isEnabled = true
  }

  private func setupView(isValidation: Bool) {
    if isValidation {
      title = l10n("Consent")
      self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
      certificateTitle.text = String(format: "Certificate type: %@", certificate?.certTypeString ?? "")
      validToLabel.text = String(format: "Expired date: %@", certificate?.exp.localDateString ?? "")
      consetsLabel.text = l10n("Consent")
      infoLabel.text = String(format: l10n("Do you agree to share the %@ certificate with %@?"),
        certificate?.certTypeString ?? "", "airline.com")
    }
  }
  
  func prepareTicketing(with acceptance: TicketingAcceptance, certificate: HCert) {
    self.ticketingAcceptance = acceptance
    self.certificate = certificate
  }
  
  @IBAction func cancelButtonAction(_ sender: Any) {
    guard loading == false else { return }
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func grandButtonAction(_ sender: Any) {
    guard loading == false, let certificate = certificate else { return }
    self.startActivity()
    ticketingAcceptance?.requestGrandPermissions(for: certificate, completion: { [weak self] response, error in
      guard error == nil, let response = response else {
        DispatchQueue.main.async {
          self?.stopActivity()
          self?.showInfoAlert(withTitle: l10n("Cannot validate the certificate"),
              message: l10n("Make sure you select the desired service and try again. If it happens again, please refer to the Re-open EU website."))
        }
        return
      }
      DispatchQueue.main.async {
        self?.stopActivity()
        self?.performSegue(withIdentifier: Segues.showValidationResult, sender: response)
      }
    })
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier {
    case Segues.showValidationResult:
      guard let validationController = segue.destination as? ValidationResultController,
      let responseModel = sender as? AccessTokenResponse else { return }
      validationController.validationResultModel = responseModel

    default:
        break
    }
  }
}
