//
//  File.swift
//  
//
//  Created by Igor Khomiak on 11.10.2021.
//

import UIKit
import Vision
import AVFoundation
import DGCCoreLibrary
import DCCInspection
import DGCVerificationCenter
import SwiftUI
import DGCSHInspection


protocol ScanWalletDelegate: AnyObject {
    func walletController(_ controller: ScanWalletController, didScanCertificate certificate: MultiTypeCertificate)
    func walletController(_ controller: ScanWalletController, didScanInfo info: CheckInQR)
    func walletController(_ controller: ScanWalletController, didFailWithError error: CertificateParsingError)
    func disableBackgroundDetection()
    func enableBackgroundDetection()
}

class ScanWalletController: UIViewController {
    private var captureSession: AVCaptureSession?
    weak var delegate: ScanWalletDelegate?

    lazy var detectBarcodeRequest = VNDetectBarcodesRequest { request, error in
      guard error == nil else {
        self.showAlert(withTitle: "Cannot read Barcode".localized,
            message: error?.localizedDescription ?? "Something went wrong.".localized)
        return
      }
      self.processClassification(request)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
      return .portrait
    }

    private var camView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        camView = UIView(frame: .zero)
        camView.translatesAutoresizingMaskIntoConstraints = false
        camView.isUserInteractionEnabled = false
        view.addSubview(camView)
        NSLayoutConstraint.activate([
          camView.topAnchor.constraint(equalTo: view.topAnchor),
          camView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
          camView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
          camView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
            
        view.backgroundColor = .init(white: 0, alpha: 1)
        
    #if targetEnvironment(simulator)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          // swiftlint:disable:next line_length
          self.observationHandler(payloadString:
        """
        {
          "protocol": "DCCVALIDATION",
          "protocolVersion": "1.0.0",
          "serviceIdentity": "https://dgca-booking-demo-eu-test.cfapps.eu10.hana.ondemand.com/api/identity",
          "privacyUrl": "https://validation-decorator.example",
          "token": "eyJ0eXAiOiJKV1QiLCJraWQiOiJiUzhEMi9XejV0WT0iLCJhbGciOiJFUzI1NiJ9.eyJpc3MiOiJodHRwczovL2RnY2EtYm9va2luZy1kZW1vLWV1LXRlc3QuY2ZhcHBzLmV1MTAuaGFuYS5vbmRlbWFuZC5jb20vYXBpL2lkZW50aXR5IiwiZXhwIjoxNjM2NjIzMTA0LCJzdWIiOiI0NmM3N2YwOS1kMGI1LTQ1NjUtYTY5NC01ZDkyMzk3NmI4M2YifQ.5EpHoZ-NBtsjI9h5encROPNGzU7MUcGFpJobffjrVsswFJTidKS2XT3PGFj3HUUvufZQRRurDbZKwOHBkzXyIA",
          "consent": "Please confirm to start the DCC Exchange flow. If you not confirm, the flow is aborted.",
          "subject": "46c77f09-d0b5-4565-a694-5d923976b83f",
          "serviceProvider": "Booking Demo"
        }
        """)
        }
    #else
        captureSession = AVCaptureSession()
        checkPermissions()
        setupCameraLiveView()
    #endif
      SquareViewFinder.create(from: self)
      createDismissButton()
    }
  
    override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      captureSession?.stopRunning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      captureSession?.startRunning()
    }

    private func createDismissButton() {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.setAttributedTitle(
         NSAttributedString(string: "Cancel".localized, attributes: [.font: UIFont.systemFont(ofSize: 22,
             weight: .semibold), .foregroundColor: UIColor.white]), for: .normal)
        button.addTarget(self, action: #selector(dismissScaner), for: .touchUpInside)
        view.addSubview(button)
         
        NSLayoutConstraint.activate([
          button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16.0),
          button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16.0)
        ])
     }
     
     @objc func dismissScaner() {
         self.dismiss(animated: true, completion: nil)
     }
}

extension ScanWalletController  {
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
          delegate?.disableBackgroundDetection()
          AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            self?.delegate?.enableBackgroundDetection()
            if !granted {
              self?.showPermissionsAlert()
            }
          }
        case .denied, .restricted:
          showPermissionsAlert()
        default:
          break
        }
    }

    private func setupCameraLiveView() {
        captureSession?.sessionPreset = .hd1280x720
        
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        
        guard let device = videoDevice,
          let videoDeviceInput = try? AVCaptureDeviceInput(device: device),
          captureSession?.canAddInput(videoDeviceInput) == true
        else {
          showAlert( withTitle: "No camera available".localized, message: "The app requires access the camera".localized)
          return
        }
        
        captureSession?.addInput(videoDeviceInput)
        
        let captureOutput = AVCaptureVideoDataOutput()
        captureOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        captureSession?.addOutput(captureOutput)
        
        configurePreviewLayer()
    }

    private func processClassification(_ request: VNRequest) {
        DispatchQueue.main.async { [self] in
        guard let barcodes = request.results else { return }
            if captureSession?.isRunning == true {
                camView.layer.sublayers?.removeSubrange(1...)
                
                if let barcode = barcodes.first {
                    var potentialQRCode: VNBarcodeObservation
                    if #available(iOS 15, *) {
                        guard let potentialCode = barcode as? VNBarcodeObservation,
                          [.Aztec, .QR, .DataMatrix].contains(potentialCode.symbology),
                          potentialCode.confidence > 0.9
                        else { return }
                        potentialQRCode = potentialCode
                    } else {
                        guard let potentialCode = barcode as? VNBarcodeObservation,
                          potentialCode.confidence > 0.9,
                              [.aztec, .qr, .dataMatrix].contains(potentialCode.symbology)
                        else { return }
                        potentialQRCode = potentialCode
                    }
                    DGCLogger.logInfo(potentialQRCode.symbology.rawValue.description)
                    observationHandler(payloadString: potentialQRCode.payloadStringValue)
                }
            }
        }
    }
  
  private func observationHandler(payloadString: String?) {
    guard let barcodeString = payloadString, !barcodeString.isEmpty else { return }
	  /// MARK: END OF SCANNING
      do {
          if let certificate = MultiTypeCertificate(from: barcodeString) {
              self.delegate?.walletController(self, didScanCertificate: certificate)
          } else if let payloadData = (payloadString ?? "").data(using: .utf8),
              let ticketing = try? JSONDecoder().decode(CheckInQR.self, from: payloadData) {
              self.delegate?.walletController(self, didScanInfo: ticketing)
          } else {
            DGCLogger.logInfo("Error when validating the certificate? \(barcodeString)")
            self.delegate?.walletController(self, didFailWithError: CertificateParsingError.unknown)
          }
      } catch SHParsingError.kidNotFound(let rawUrl) {
          print("failed with SHParsing error.")
          // since kid is not in list of trusted issuers, make sure to ask user first
          self.showAlert(title: "WARNING", subtitle: "Unknown issuer. Do you wish to proceed at your own risk?", actionTitle: "Ignore warning", cancelTitle: "Back to safety") { response in
              if response { // user wishes to proceed
                  TrustedListLoader.resolveUnknownIssuer(rawUrl) { kidList, result in
                      if let certificate = MultiTypeCertificate(from: barcodeString) {
                          self.delegate?.walletController(self, didScanCertificate: certificate)
                      } else {
                          DGCLogger.logInfo("Error when validating the certificate? \(barcodeString)")
                          self.delegate?.walletController(self, didFailWithError: CertificateParsingError.unknown)
                      }
                  }
              } else { // user wishes to not proceed
                  DGCLogger.logInfo("User wished to abort scanning certificate.")
                  self.delegate?.walletController(self, didFailWithError: CertificateParsingError.unknown)
              }
          }
      } catch {
          print("Generic error was thrown")
          delegate?.walletController(self, didFailWithError: CertificateParsingError.unknown)
      }
    
  }
}

extension ScanWalletController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
      from connection: AVCaptureConnection) {
      guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
      
      let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
      do {
        try imageRequestHandler.perform([detectBarcodeRequest])
      } catch {
        DGCLogger.logError(error)
      }
    }
}

extension ScanWalletController {
    private func configurePreviewLayer() {
      guard let captureSession = captureSession else { return }
        
      let cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
      cameraPreviewLayer.videoGravity = .resizeAspectFill
      cameraPreviewLayer.connection?.videoOrientation = .portrait
      cameraPreviewLayer.frame = view.frame
      camView.layer.insertSublayer(cameraPreviewLayer, at: 0)
    }
    
    private func showAlert(withTitle title: String, message: String) {
      DispatchQueue.main.async {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK".localized, style: .default))
        self.present(alertController, animated: true)
      }
    }

    private func showPermissionsAlert() {
        showAlert(withTitle: "Wallet App would like to access the camera".localized,
            message: "Please open the Settings and grant permission for this app to use your camera.".localized
        )
    }
}
