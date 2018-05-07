//
//  QRScanVC.swift
//  Engauge
//
//  Created by Brennan Linse on 5/3/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import FirebaseAuth
import AVFoundation

class QRScanVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    // MARK: Outlets
    
    
    
    
    // MARK: Properties
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var frameView: UIView?
    
    var canScan = true
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureSession = AVCaptureSession()
        
        // Initialize a device discovery session to find the back camera.
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: AVCaptureDevice.Position.back)
        
        // Get the back camera via the discovery session.
        guard let backCamera = deviceDiscoverySession.devices.first else {
            // TODO: Couldn't find the camera.
            print("Couldn't discover the camera")
            return
        }
        
        do {
            // Add the back camera input as an input to the capture session.
            let inputBackCamera = try AVCaptureDeviceInput(device: backCamera)
            captureSession?.addInput(inputBackCamera)
            
            // Initialize a metadata output object and set it as the output of the capture session.
            let outputMetadata = AVCaptureMetadataOutput()
            captureSession?.addOutput(outputMetadata)
            
            // Set the output's delegate and metadata types (We're only interested in QR codes)
            outputMetadata.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            outputMetadata.metadataObjectTypes = [.qr]
            
            // Add the video preview layer as a sublayer of the main view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = .resizeAspectFill
            videoPreviewLayer?.frame = self.view.layer.bounds
            self.view.layer.addSublayer(videoPreviewLayer!)
            
            // Start capturing video.
            captureSession?.startRunning()
            
            // Initialize the green frame
            frameView = UIView()
            if let theFrame = frameView {
                theFrame.layer.borderColor = UIColor.green.cgColor
                theFrame.layer.borderWidth = 2
                self.view.addSubview(theFrame)
                self.view.bringSubview(toFront: theFrame)
            }
        } catch {
            // TODO: Couldn't initialize the back camera input object.
            print("Couldn't initialize the back camera input")
            return
        }
    }
    
    // Whenever this view first appears, scanning is allowed and the camera works.
    override func viewDidAppear(_ animated: Bool) {
        canScan = true
        captureSession?.startRunning()
    }
    
    // Whenever this view is about to disappear, disable the camera.
    override func viewWillDisappear(_ animated: Bool) {
        hideFrameView()
        captureSession?.stopRunning()
    }
    
    
    
    
    // MARK: QR Scanning
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        print("Received a metadata object")
        
        // Were there any objects detected?
        guard !metadataObjects.isEmpty else {
            hideFrameView()
            print("Didn't detect any output objects")
            return
        }
        
        // Did we detect a machine-readable code?
        guard let detectedObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject else {
            hideFrameView()
            print("Couldn't convert the detected object to a machine readable code.")
            return
        }
        
        // Was the code a QR code?
        guard detectedObject.type == .qr else {
            hideFrameView()
            print("The detected code wasn't a QR code")
            return
        }
        
        // Can we get the code's location to show in the preview layer?
        guard let qrCodeObject = videoPreviewLayer?.transformedMetadataObject(for: detectedObject) else {
            hideFrameView()
            print("Couldn't get the QR code's location on-screen!")
            return
        }
        
        // Show the green frame view on-screen around the QR code
        frameView?.frame = qrCodeObject.bounds
        
        // Is the QR code's payload/data accessible?
        guard let scannedEventID = detectedObject.stringValue else {
            hideFrameView()
            print("Couldn't get the QR code's payload!")
            return
        }
        
        // Can we get the current user's UID?
        guard let currUserUID = Auth.auth().currentUser?.uid else {
            hideFrameView()
            print("Nobody is signed in!")
            return
        }
        
        // Is scanning allowed at the moment?
        guard canScan else {
            print("Can't scan!")
            return
        }
        print("Scanning is allowed")
        canScan = false
        
        // Process the scan accordingly.
        DataService.instance.processQRScanForEvent(withID: scannedEventID, byUserWithUID: currUserUID) { (success, error) in
            guard error == nil else {
                // There was an error processing the QR scan.
                self.handleScanError(error!)
                return
            }
            
            // At this point, the scan is successful.
            // TODO: Stop the captureSession from running?
            self.performSegue(withIdentifier: "toQRScanSuccessVC", sender: scannedEventID)
        }
    }
    
    /**
     Shows an error alert based on an error passed back from an unsuccessful QR code scan.
     */
    private func handleScanError(_ error: DataService.QRScanError) {
        var errTitle = "Error"
        var errMsg = "There was an issue processing your scan."
        
        switch error {
            
        case .userAlreadyScanned:
            errTitle = "Error: Already Scanned"
            errMsg = "We appreciate your enthusiasm, but you only need to scan once per event. Thanks for attending!"
            
        case .couldNotRetrieveSchoolID:
            errTitle = "Database Error"
            errMsg = "There was an issue verifying your school's ID."
            
        case .couldNotCompleteTransaction:
            errTitle = "Error: Bad Transaction"
            errMsg = "Could not complete the point transaction. Try again?"
            
        case .databaseError:
            errTitle = "Database Error"
            errMsg = "There was an issue verifying the event information. Are you sure that was an Engauge QR code?"
            
        case .eventNotInProgress:
            errTitle = "Error: Not in Progress"
            errMsg = "You may only scan during the event (between its listed start and end time)."
        case .badEventID:
            errTitle = "Error: Invalid QR Code"
            errMsg = "Didn't recognize that code. Are you sure it was an Engauge QR code?"
        }
        
        self.showErrorAlert(title: errTitle, message: errMsg, dismissHandler: { (okAction) in
            self.hideFrameView()
            self.canScan = true
        })
        
    }
    
    private func hideFrameView() {
        frameView?.frame = CGRect.zero
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toQRScanSuccessVC":
            if let successScreen = segue.destination.contentsViewController as? QRScanSuccessVC, let scannedEventID = sender as? String {
                successScreen.eventID = scannedEventID
            }
            
        default:
            break
        }
    }
    
    
    
    
    // MARK: Deinitializer
    deinit {
        print("Deallocating an instance of QRScanVC")
    }
    
}
