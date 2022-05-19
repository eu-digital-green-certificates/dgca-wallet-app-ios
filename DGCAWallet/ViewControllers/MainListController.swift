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
//  MainListController.swift
//  DGCAWallet
//
//  Created by Yannick Spreen on 4/25/21.
//

// swiftlint:disable file_length

import UIKit
import UniformTypeIdentifiers
import MobileCoreServices
import DGCCoreLibrary
import DGCVerificationCenter

#if canImport(DCCInspection)
import DCCInspection
#endif

#if canImport(DGCSHInspection)
import DGCSHInspection
#endif

let dataReloadedNotification = Notification.Name("DataReloaded")

class MainListController: UIViewController {
	let refreshControl = UIRefreshControl()
	let center = NotificationCenter.default
	fileprivate enum SegueIdentifiers {
		static let showScannerSegue = "showScannerSegue"
		static let showServicesList = "showServicesList"
		static let showSettingsController = "showSettingsController"
        
        static let showSavedDCCCertificate = "showSavedDCCCertificate"
        static let showSavedICAOCertificate = "showSavedICAOCertificate"
        static let showSavedDIVOCCertificate = "showSavedDIVOCCertificate"
         static let showSavedSHCCertificate = "showSavedSHCCertificate"

		static let showScannedDCCCertificate = "showScannedDCCCertificate"
        static let showScannedICAOCertificate = "showScannedICAOCertificate"
        static let showScannedDIVOCCertificate = "showScannedDIVOCCertificate"
        static let showScannedSHCertificate = "showScannedSHCertificate"

		static let showPDFViewer = "showPDFViewer"
		static let showImageViewer = "showImageViewer"
	}
	
	private enum TableSection: Int, CaseIterable {
		case multiTypeCertificates
        case images
        case pdfs
	}
	
	@IBOutlet fileprivate weak var addButton: RoundedButton!
	@IBOutlet fileprivate weak var table: UITableView!
	@IBOutlet fileprivate weak var emptyView: UIView!
	@IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet fileprivate weak var titleLabel: UILabel!
    
	private var expireDataTimer: Timer?
	private var scannedToken: String = ""
	private var loading = false
    private var nearCommunicatingHelper: NFCHelper?
    
    var downloadedDataHasExpired: Bool {
        return DCCDataCenter.downloadedDataHasExpired
    }
    
    var certificates: [MultiTypeCertificate] = []
    
    var listImageElements: [SavedImage] {
        return DCCDataCenter.images
    }
    
    var listPdfElements: [SavedPDF] {
        return DCCDataCenter.pdfs
    }
    
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	deinit {
		center.removeObserver(self)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
        center.addObserver(forName: dataReloadedNotification, object: nil, queue: .main) { [unowned self] notification in
            self.refresh()
        }
		self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
		self.titleLabel.text = "Certificate Wallet".localized
		self.addButton.setTitle("Add New".localized, for: .normal)
		refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
		refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
		table.refreshControl = refreshControl
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.isNFCFunctionality = false
        if #available(iOS 13.0, *) {
            let scene = self.sceneDelegate
            scene?.isNFCFunctionality = false
        }
        expireDataTimer = Timer.scheduledTimer(timeInterval: 1800, target: self, selector: #selector(reloadExpiredData),
            userInfo: nil, repeats: true)
        
        self.refresh()
	}
	
	@objc func refresh() {
        certificates = []
        #if canImport(DCCInspection)
        let listCertElements = DCCDataCenter.certStrings.reversed()
        for certString in listCertElements {
            guard let hCert: HCert = certString.cert else { continue }
            let multiTypeCert = MultiTypeCertificate(with: hCert,
                type: .dcc,
                scannedDate: certString.date,
                storedTan: certString.storedTAN,
                ruleCountryCode: nil)
            certificates.append(multiTypeCert)
        }
        #endif
        
        #if canImport(DGCSHInspection)
        let certStrings = SHDataCenter.certStrings.reversed()
        for cString in certStrings {
            guard let shCert: SHCert = cString.cert else { continue }
            let multiTypeCert = MultiTypeCertificate(with: shCert,
                 type: .shc,
                 scannedDate: cString.date,
                 storedTan: nil,
                 ruleCountryCode: nil)
            certificates.append(multiTypeCert)
        }
        #endif

        DispatchQueue.main.async {
            self.emptyView.alpha = self.certificates.isEmpty && self.listImageElements.isEmpty && self.listPdfElements.isEmpty ? 1 : 0
            self.table.reloadData()
            self.refreshControl.endRefreshing()
        }
	}
    
	// MARK: - Actions
	@objc func reloadExpiredData() {
        if downloadedDataHasExpired {
             showAlertReloadDatabase()
        }
	}
	
	func showAlertReloadDatabase() {
		let alert = UIAlertController(title: "Reload data?".localized, message: "The update may take some time.".localized, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Later".localized, style: .default, handler: { _ in }))
		alert.addAction(UIAlertAction(title: "Reload".localized, style: .default, handler: { (_: UIAlertAction) in
            DGCVerificationCenter.shared.updateStoredData(appType: .wallet, completion: { _ in })
		}))
		self.present(alert, animated: true, completion: nil)
	}
	
	// MARK: - Private UI methods
	private func startActivity() {
		loading = true
		activityIndicator.startAnimating()
		addButton.isEnabled = false
		addButton.backgroundColor = UIColor.walletLightBlue
	}
	
	private func stopActivity() {
		loading = false
		activityIndicator.stopAnimating()
		addButton.isEnabled = true
		addButton.backgroundColor = UIColor.walletBlue
	}
    
	// MARK: Actions
	@IBAction func addNew() {
		guard loading == false else { return }
		
		let menuActionSheet = UIAlertController(title: "Add new?".localized, message: "Do you want to add new certificate, image or PDF file?".localized, preferredStyle: UIAlertController.Style.actionSheet)
		
		menuActionSheet.addAction(UIAlertAction(title: "Scan certificate".localized, style: UIAlertAction.Style.default,
            handler: {[weak self] _ in
                self?.scanNewCertificate()
            })
		)
		menuActionSheet.addAction(UIAlertAction(title: "Image import".localized, style: UIAlertAction.Style.default,
            handler: { [weak self] _ in
                self?.addImageActivity()
            })
		)
		menuActionSheet.addAction(UIAlertAction(title: "PDF Import".localized, style: UIAlertAction.Style.default,
            handler: { [weak self] _ in
                self?.addPdf()
            })
		)
		menuActionSheet.addAction(UIAlertAction(title: "NFC Import".localized, style: UIAlertAction.Style.default,
            handler: { [weak self] _ in
                self?.scanNFC()
            })
		)
		menuActionSheet.addAction(UIAlertAction(title: "Cancel".localized, style: UIAlertAction.Style.cancel, handler: nil))
		present(menuActionSheet, animated: true, completion: nil)
	}
		
    private func processBarcode(barcode: String?) {
        guard let barcodeString = barcode, !barcodeString.isEmpty else { return }
        if CertificateApplicant.isApplicableDCCFormat(payload: barcodeString) {
            do {
                let certificate = try MultiTypeCertificate(from: barcodeString)
                self.walletController(self, didScanCertificate: certificate)

            } catch let error as CertificateParsingError {
                self.showAlertWithError(error)
            } catch {
                self.showAlertWithError(CertificateParsingError.invalidStructure)
            }
            
        } else if CertificateApplicant.isApplicableSHCFormat(payload: barcodeString) {
            do {
                let certificate = try MultiTypeCertificate(from: barcodeString)
                self.walletController(self, didScanCertificate: certificate)
                
            } catch CertificateParsingError.kidNotFound(let rawUrl) {
                DGCLogger.logInfo("Error kidNotFound when parse SH card.")
                self.showAlert(title: "Unknown issuer of Smart Card".localized,
                    subtitle: "Do you want to continue to identify the issuer?",
                    actionTitle: "Continue".localized, cancelTitle: "Cancel".localized ) { response in
                    if response {
                        #if canImport(DGCSHInspection)
                        TrustedListLoader.resolveUnknownIssuer(rawUrl) { kidList, result in
                            if let certificate = try? MultiTypeCertificate(from: barcodeString) {
                                self.walletController(self, didScanCertificate: certificate)
                            } else {
                                DGCLogger.logInfo("Error validating barcodeString: \(barcodeString)")
                                self.showAlertWithError(CertificateParsingError.unknownFormat)
                            }
                        }
                        #endif
                        
                    } else { // user cancels
                        DGCLogger.logInfo("User cancelled verifying.")
                    }
                }
                
            } catch let error as CertificateParsingError {
                self.showAlertWithError(error)
            } catch {
                self.showAlertWithError(CertificateParsingError.invalidStructure)
            }
            
        } else if let payloadData = barcodeString.data(using: .utf8),
            let ticketing = try? JSONDecoder().decode(CheckInQR.self, from: payloadData) {
            self.walletController(self, didScanInfo: ticketing)
        
        } else {
            DGCLogger.logInfo("Cannot recognise barcodeString: \(barcodeString)")
            let alertController: UIAlertController = {
                let controller = UIAlertController(title: "Cannot read NFC".localized,
                    message: "An error occurred while reading NFC".localized, preferredStyle: .alert)
                
                let actionRetry = UIAlertAction(title: "Retry".localized, style: .default) { _ in
                    self.scanNFC()
                }
                controller.addAction(actionRetry)
                
                let actionOk = UIAlertAction(title: "Cancel".localized, style: .cancel)
                controller.addAction(actionOk)
                return controller
            }()
            self.present(alertController, animated: true)
        }
    }
    
	@IBAction func settingsTapped(_ sender: UIButton) {
		self.performSegue(withIdentifier: SegueIdentifiers.showSettingsController, sender: nil)
	}
	
	// MARK: Tasks
	private func scanNewCertificate() {
		performSegue(withIdentifier: SegueIdentifiers.showScannerSegue, sender: nil)
	}
	
	private func addPdf() {
		let pdfPicker: UIDocumentPickerViewController
		if #available(iOS 14.0, *) {
			let supportedTypes: [UTType] = [UTType.pdf]
			pdfPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
		} else {
			pdfPicker = UIDocumentPickerViewController(documentTypes: [kUTTypePDF as String], in: .open)
		}
		pdfPicker.delegate = self
		present(pdfPicker, animated: true, completion: nil)
	}
    
	private func scanNFC() {
		let appDelegate = UIApplication.shared.delegate as? AppDelegate
		appDelegate?.isNFCFunctionality = true
		if #available(iOS 13.0, *) {
			let scene = self.sceneDelegate
			scene?.isNFCFunctionality = true
		}
        if self.nearCommunicatingHelper == nil {
            let helper = NFCHelper()
            helper.delegate = self
            self.nearCommunicatingHelper = helper
        }
        self.nearCommunicatingHelper?.restartSession()
	}
	
	// MARK: Navifation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case SegueIdentifiers.showScannerSegue:
			guard let scanController = segue.destination as? ScanWalletController else { return }
			scanController.modalPresentationStyle = .fullScreen
			scanController.delegate = self
			
		case SegueIdentifiers.showSettingsController:
			guard let navController = segue.destination as? UINavigationController,
				  let _ = navController.viewControllers.first as? SettingsTableController else { return }
			
		case SegueIdentifiers.showServicesList:
			guard let serviceController = segue.destination as? ServerListController,
			    let listOfServices = sender as? ServerListResponse else { return }
			serviceController.serverListInfo = listOfServices
			
		case SegueIdentifiers.showPDFViewer:
			guard let serviceController = segue.destination as? PDFViewerController,
			    let pdf = sender as? SavedPDF else { return }
			serviceController.savedPDF = pdf
			
		case SegueIdentifiers.showImageViewer:
			guard let serviceController = segue.destination as? ImageViewerController,
			    let savedImage = sender as? SavedImage else { return }
			serviceController.savedImage = savedImage
			
        case SegueIdentifiers.showSavedDCCCertificate:
            guard let serviceController = segue.destination as? DCCViewerController else { return }
            if let savedCertificate = sender as? MultiTypeCertificate {
                serviceController.certificate = savedCertificate
                serviceController.isSaved = true
                serviceController.certDate = savedCertificate.scannedDate
                serviceController.tan = savedCertificate.storedTan
            }
            serviceController.delegate = self

		case SegueIdentifiers.showScannedDCCCertificate:
			guard let serviceController = segue.destination as? DCCViewerController else { return }
			if let certificate = sender as? MultiTypeCertificate {
                serviceController.certificate = certificate
				serviceController.isSaved = false
			}
			serviceController.delegate = self
            
        case SegueIdentifiers.showScannedICAOCertificate:
            ()  // TODO implement ICAOCertificateViewerController
            
        case SegueIdentifiers.showScannedDIVOCCertificate:
            ()  // TODO implement ICAOCertificateViewerController
			
		case SegueIdentifiers.showScannedSHCertificate:
			guard let shVC = segue.destination as? CardContainerController else { return }
			if let certificate = sender as? MultiTypeCertificate {
				shVC.certificate = certificate
			}
            shVC.editMode = false
            shVC.delegate = self
            
        case SegueIdentifiers.showSavedSHCCertificate:
            guard let shVC = segue.destination as? CardContainerController else { return }
            if let certificate = sender as? MultiTypeCertificate {
                shVC.certificate = certificate
            }
            shVC.editMode = true
            shVC.delegate = self
            
		default:
			break
		}
	}
    
    private func showAlertWithError(_ error: Error) {
        DispatchQueue.main.async {
            switch error {
            case CertificateParsingError.invalidStructure:
                self.showAlert(withTitle: "Cannot read Barcode".localized, message: "Cryptographic signature is invalid".localized)
            case CertificateParsingError.unknownFormat:
                self.showAlert(withTitle: "Cannot read Barcode".localized, message: "Unknown certificate type.".localized)
            default:
                self.showAlert(withTitle: "Cannot read Barcode".localized, message: "Unknown barcode format.".localized)
            }
        }
    }
    
    private func showAlert(withTitle title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK".localized, style: .default))
            self.present(alertController, animated: true)
        }
    }
}

// MARK: - ScanWalletDelegate
extension MainListController: ScanWalletDelegate {
	func walletController(_ controller: UIViewController, didFailWithError error: CertificateParsingError) {
		DispatchQueue.main.async {
			self.showInfoAlert(withTitle: "Cannot read Barcode".localized, message: "Something went wrong.".localized)
		}
	}
	
	func disableBackgroundDetection() {
        SecureBackground.shared.paused = true
	}
	
	func enableBackgroundDetection() {
        SecureBackground.shared.paused = false
	}
	
	func walletController(_ controller: UIViewController, didScanCertificate certificate: MultiTypeCertificate) {
		DispatchQueue.main.async { [weak self] in
            self?.dismiss(animated: true, completion: nil)
            switch certificate.certificateType {
            case .unknown:
                // TODO: Show Alert here
                break
            case .dcc:
                self?.performSegue(withIdentifier: SegueIdentifiers.showScannedDCCCertificate, sender: certificate)
            case .icao:
                self?.performSegue(withIdentifier: SegueIdentifiers.showScannedICAOCertificate, sender: certificate)
            case .divoc:
                self?.performSegue(withIdentifier: SegueIdentifiers.showScannedDIVOCCertificate, sender: certificate)
            case .shc:
                self?.performSegue(withIdentifier: SegueIdentifiers.showScannedSHCertificate, sender: certificate)
            }
		}
	}
	
	func walletController(_ controller: UIViewController, didScanInfo ticketing: CheckInQR) {
		if scannedToken == ticketing.token {
			return
		}
		scannedToken = ticketing.token
		startActivity()
		IdentityService.requestListOfServices(ticketingInfo: ticketing) { [weak self] services, error in
			guard error == nil else {
				self?.showInfoAlert(withTitle: "This certificate is not supported".localized, message: "")
				return
			}
			DispatchQueue.main.async {
				self?.stopActivity()
				self?.dismiss(animated: true, completion: {
					self?.scannedToken = ""
					self?.performSegue(withIdentifier: SegueIdentifiers.showServicesList, sender: services)
				})
			}
		}
	}
}

// MARK: CertificateManaging
extension MainListController: CertificateManaging {
	func certificateViewer(_ controller: UIViewController, didDeleteCertificate certificate: MultiTypeCertificate) {
		DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150)) {
            self.refresh()
		}
	}
	
    func certificateViewer(_ controller: UIViewController, didAddCeCertificate certificate: MultiTypeCertificate) {
        switch certificate.certificateType {
        case .dcc:
            guard let certString = DCCDataCenter.certStrings.last else { return }
            GatewayConnection.lookup(certStrings: [certString]) { success, _, _ in
                self.refresh()
            }
            
        default:
            self.refresh()
        }
    }
}

// MARK: UITable delegate
extension MainListController: UITableViewDelegate, UITableViewDataSource {
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case TableSection.multiTypeCertificates.rawValue:
			return certificates.count
            
        case TableSection.images.rawValue:
			return listImageElements.count
            
		case TableSection.pdfs.rawValue:
			return listPdfElements.count
            
		default:
			return .zero
		}
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return TableSection.allCases.count
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch section {
		case TableSection.multiTypeCertificates.rawValue:
			return !certificates.isEmpty ? "Certificates".localized : nil
            
		case TableSection.images.rawValue:
			return !listImageElements.isEmpty ? "Images".localized : nil
            
		case TableSection.pdfs.rawValue:
			return !listPdfElements.isEmpty ? "PDF files".localized : nil
            
		default:
			return nil
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch indexPath.section {
		case TableSection.multiTypeCertificates.rawValue:
			guard let walletCell = table.dequeueReusableCell(withIdentifier: "WalletCell", for: indexPath) as? WalletCell
			else { return UITableViewCell() }
			
            walletCell.setupCell(certificates[indexPath.row])
			return walletCell
            
		case TableSection.images.rawValue:
			guard let imageCell = table.dequeueReusableCell(withIdentifier: "ImageTableViewCell", for: indexPath) as? ImageTableViewCell
			else { return UITableViewCell() }
			
			imageCell.setImage(image: listImageElements[indexPath.row])
			return imageCell
			
		case TableSection.pdfs.rawValue:
			guard let imageCell = table.dequeueReusableCell(withIdentifier: "PDFTableViewCell", for: indexPath) as? PDFTableViewCell
			else { return UITableViewCell() }
			
			imageCell.setPDF(pdf: listPdfElements[indexPath.row])
			return imageCell
			
		default:
			return UITableViewCell()
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard loading == false else { return }
		
		table.deselectRow(at: indexPath, animated: true)
		switch indexPath.section {
		case TableSection.multiTypeCertificates.rawValue:
            let cert = certificates[indexPath.row]
            switch cert.certificateType {
            case .dcc:
                self.performSegue(withIdentifier: SegueIdentifiers.showSavedDCCCertificate, sender: certificates[indexPath.row])
            case .icao:
                self.performSegue(withIdentifier: SegueIdentifiers.showSavedICAOCertificate, sender: certificates[indexPath.row])
            case .divoc:
                self.performSegue(withIdentifier: SegueIdentifiers.showSavedDIVOCCertificate, sender: certificates[indexPath.row])
            case .shc:
                self.performSegue(withIdentifier: SegueIdentifiers.showSavedSHCCertificate, sender: certificates[indexPath.row])
            default:
                break
            }
			
		case TableSection.images.rawValue:
			self.performSegue(withIdentifier: SegueIdentifiers.showImageViewer, sender: listImageElements[indexPath.row])
			
		case TableSection.pdfs.rawValue:
			self.performSegue(withIdentifier: SegueIdentifiers.showPDFViewer, sender: listPdfElements[indexPath.row])
			
		default:
			break
		}
	}
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		switch indexPath.section {
		case TableSection.multiTypeCertificates.rawValue:
			let savedCert = certificates[indexPath.row]
			showAlert( title: "Delete Certificate".localized, subtitle: "cert.delete.body".localized,
                actionTitle: "Confirm".localized, cancelTitle: "Cancel".localized) { [weak self] in
				if $0 {
                    switch savedCert.certificateType {
                    case .dcc:
                        DCCDataCenter.localDataManager.remove(withDate: savedCert.scannedDate) { _ in
                            DispatchQueue.main.async {
                                self?.refresh()
                            }
                        }
                        break
                    case .shc:
                        SHDataCenter.shDataManager.remove(withDate: savedCert.scannedDate) { _ in
                            DispatchQueue.main.async {
                                self?.refresh()
                            }
                        }
                    default:
                        break
                    }
				}
			}
			
		case TableSection.images.rawValue:
			let savedImage = listImageElements[indexPath.row]
			showAlert( title: "Delete Certificate".localized, subtitle: "cert.delete.body".localized,
                actionTitle: "Confirm".localized, cancelTitle:"Cancel".localized) { [weak self] in
				if $0 {
					DCCDataCenter.localImageManager.deleteImage(with: savedImage.identifier) { _ in
						DispatchQueue.main.async {
							self?.refresh()
						}
					}
				}
			}
            
		case TableSection.pdfs.rawValue:
			let savedPDF = listPdfElements[indexPath.row]
			showAlert( title: "Delete Certificate".localized, subtitle: "cert.delete.body".localized,
                actionTitle: "Confirm".localized, cancelTitle: "Cancel".localized) { [weak self] in
				if $0 {
					DCCDataCenter.localImageManager.deletePDF(with: savedPDF.identifier) { _ in
						DispatchQueue.main.async {
							self?.refresh()
						}
					}
				}
			}
		default:
			break
		}
	}
}

// MARK: UIImagePicker delegate
extension MainListController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func addImageActivity() {
		let alert = UIAlertController(title: "Get Image from".localized, message: nil, preferredStyle: .actionSheet)
		let cameraAction = UIAlertAction(title: "Camera".localized, style: .default) {[weak self] _ in
			alert.dismiss(animated: true, completion: nil)
			self?.openCamera()
		}
		let galleryAction = UIAlertAction(title: "Gallery".localized, style: .default) {[weak self] _ in
			alert.dismiss(animated: true, completion: nil)
			self?.openGallery()
		}
		let cancelAction = UIAlertAction(title: "Cancel".localized, style: .cancel)
		
		// Add the actions
		alert.addAction(cameraAction)
		alert.addAction(galleryAction)
		alert.addAction(cancelAction)
		present(alert, animated: true, completion: nil)
	}
	
    func openCamera() {
		if UIImagePickerController.isSourceTypeAvailable(.camera) {
			let picker = UIImagePickerController()
			picker.delegate = self
			picker.sourceType = .camera
			present(picker, animated: true, completion: nil)
		} else {
			let alertController: UIAlertController = {
				let controller = UIAlertController(title:"Cannot scan".localized, message: "You don't have a camera.".localized,  preferredStyle: .alert)
				let action = UIAlertAction(title: "OK".localized, style: .default)
				controller.addAction(action)
				return controller
			}()
			self.present(alertController, animated: true)
		}
	}
	
	func openGallery() {
		let picker = UIImagePickerController()
		picker.delegate = self
		picker.sourceType = .photoLibrary
		present(picker, animated: true, completion: nil)
	}
	
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		picker.dismiss(animated: true, completion: nil)
	}
	
	func imagePickerController(_ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
		picker.dismiss(animated: true, completion: nil)
		guard let image = info[.originalImage] as? UIImage else {
			fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
		}
		tryFoundQRCodeIn(image: image)
	}
	
	@objc func imagePickerController(_ picker: UIImagePickerController, pickedImage: UIImage?) {
		guard let pickedImage = pickedImage else { return }
		tryFoundQRCodeIn(image: pickedImage)
	}
}

// MARK: QR Code, PDF. Image sources
extension MainListController {
	private func tryFoundQRCodeIn(image: UIImage) {
		if let qrString = image.qrCodeString(),
           CertificateApplicant.isApplicableFormatForVerification(payload: qrString) {
        
           if let certificate = try? MultiTypeCertificate(from: qrString) {
                self.saveQrCode(certificate: certificate)
           } else {
                self.saveImage(image: image)
           }

		} else {
			self.saveImage(image: image)
		}
	}
	
    private func saveQrCode(certificate: MultiTypeCertificate) {
        switch certificate.certificateType {
        case .unknown:
            // TODO: Show alert here
            break
        case .dcc:
            self.performSegue(withIdentifier: SegueIdentifiers.showScannedDCCCertificate, sender: certificate)
        case .icao:
            self.performSegue(withIdentifier: SegueIdentifiers.showScannedICAOCertificate, sender: certificate)
        case .divoc:
            self.performSegue(withIdentifier: SegueIdentifiers.showScannedDIVOCCertificate, sender: certificate)
        case .shc:
            self.performSegue(withIdentifier: SegueIdentifiers.showScannedSHCertificate, sender: certificate)
        }
    }
	
	private func saveImage(image: UIImage) {
		showInputDialog(title: "Save image".localized, subtitle: "Please enter the image name".localized,
                inputPlaceholder: "filename".localized) { [weak self] fileName in
			let savedImg = SavedImage(fileName: fileName ?? UUID().uuidString, image: image)
			
			self?.startActivity()
			DCCDataCenter.localImageManager.add(savedImage: savedImg) { _ in
				DispatchQueue.main.async {
					self?.stopActivity()
					self?.refresh()
					let rowCount = DCCDataCenter.images.count
					if rowCount > 0 {
						let scrollToNum = rowCount - 1
						let path = IndexPath(row: scrollToNum, section: TableSection.images.rawValue)
						DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150)) {
							self?.table.scrollToRow(at: path, at: .bottom, animated: true)
							self?.table.selectRow(at: path, animated: true, scrollPosition: .bottom)
							DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(350)) {
								self?.table.deselectRow(at: path, animated: true)
							}
						}
					}
				}
			} // end add
		}
	}
}

// MARK: PDF Document Delegate
extension MainListController: UIDocumentPickerDelegate {
	private func convertPDF(at sourceURL: URL, dpi: CGFloat = 200) throws -> [UIImage] {
		let pdfDocument = CGPDFDocument(sourceURL as CFURL)!
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue
		var images = [UIImage]()
		DispatchQueue.concurrentPerform(iterations: pdfDocument.numberOfPages) { index in
			// Page number starts at 1, not 0
			let pdfPage = pdfDocument.page(at: index + 1)!
			let mediaBoxRect = pdfPage.getBoxRect(.mediaBox)
			let scale = dpi / 72.0
			let width = Int(mediaBoxRect.width * scale)
			let height = Int(mediaBoxRect.height * scale)
			if let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) {
                context.interpolationQuality = .high
                context.setFillColor(UIColor.white.cgColor)
                context.fill(CGRect(x: 0, y: 0, width: width, height: height))
                context.scaleBy(x: scale, y: scale)
                context.drawPDFPage(pdfPage)
                if let image = context.makeImage() {
                    images.append(UIImage(cgImage: image))
                }
            }
		}
		return images
	}
	
	private func checkQRCodesInPDFFile(url: NSURL) {
		guard let images = try? convertPDF(at: url as URL), !images.isEmpty else {
			savePDFFile(url: url)
			return
		}
        
		for image in images {
            if let qrString = image.qrCodeString(),
                CertificateApplicant.isApplicableFormatForVerification(payload: qrString) {
                if let certificate = try? MultiTypeCertificate(from: qrString) {
                     self.saveQrCode(certificate: certificate)
                } else {
                    savePDFFile(url: url)
                    break
                }
            } else {
                savePDFFile(url: url)
                break
            }
		}
	}
	
	private func savePDFFile(url: NSURL) {
		showInputDialog(title: "Save PDF file".localized, subtitle: "Please enter the pdf file name".localized,
                inputPlaceholder: "filename".localized) { [weak self] fileName in
			let pdf = SavedPDF(fileName: fileName ?? UUID().uuidString, pdfUrl: url as URL)
			
			self?.startActivity()
			DCCDataCenter.localImageManager.add(savedPdf: pdf) { _ in
				DispatchQueue.main.async {
					self?.stopActivity()
					self?.table.reloadData()
					let rowsCount = DCCDataCenter.pdfs.count
					if rowsCount > 0 {
						let scrollToNum = rowsCount-1
						let path = IndexPath(row: scrollToNum, section: TableSection.pdfs.rawValue)
						
						DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150)) {
							self?.table.scrollToRow(at: path, at: .bottom, animated: true)
							self?.table.selectRow(at: path, animated: true, scrollPosition: .bottom)
							// let's add time for app to scroll down (0.35 sec)
							
							DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(350)) {
								self?.table.deselectRow(at: path, animated: true)
							}
						}
					}
				}
			} // end add
		} // end alert action
	}
	
	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		guard let url = urls.first else { return }
		
		if controller.documentPickerMode == .import {
			checkQRCodesInPDFFile(url: url as NSURL)
		}
	}
	
	private func documentPicker(controller: UIDocumentPickerViewController, didPickDocumentAtURL url: NSURL) {
		if controller.documentPickerMode == .import {
			checkQRCodesInPDFFile(url: url)
		}
	}
}

// MARK: - NFC Result
extension MainListController: NFCCommunicating {
    func onNFCResult(_ result: Bool, message: String) {
        DGCLogger.logInfo("Received NFC: \(message)")
        guard result, !message.isEmpty else { return }
        
        let barcodeString = message
        DispatchQueue.main.async { [weak self] in
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            appDelegate?.isNFCFunctionality = false
            if #available(iOS 13.0, *) {
                let scene = self?.sceneDelegate
                scene?.isNFCFunctionality = false
            }
            self?.processBarcode(barcode: barcodeString)
        }
    }
}
