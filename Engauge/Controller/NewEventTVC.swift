//
//  NewEventTVC.swift
//  Engauge
//
//  Created by Brennan Linse on 3/26/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import CoreImage
import FirebaseAuth
import FirebaseStorage

class NewEventTVC: UITableViewController, UIPickerViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField! { didSet { nameTextField.delegate = self } }
    @IBOutlet weak var locationTextField: UITextField! { didSet { locationTextField.delegate = self } }
    @IBOutlet weak var descriptionTextView: UITextView! {
        didSet {
            descriptionTextView.delegate = self
            let dismissAccessory = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
            dismissAccessory.backgroundColor = UIColor.lightGray
            
            let label = UILabel(frame: dismissAccessory.bounds)
            label.textColor = UIColor.white
            label.textAlignment = .center
            let textAttributes: [NSAttributedStringKey : Any] = [.font : UIFont(name: "Avenir", size: 18) as Any]
            let dismissText = NSAttributedString(string: "Tap to dismiss keyboard", attributes: textAttributes)
            label.attributedText = dismissText
            dismissAccessory.addSubview(label)
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleDismissKeyboardAccessoryTapped))
            dismissAccessory.addGestureRecognizer(tap)
            descriptionTextView.inputAccessoryView = dismissAccessory
        }
    }
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var startTimePicker: UIDatePicker!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var endTimePicker: UIDatePicker!
    
    
    
    
    // MARK: Properties
    
    var eventCreated: Event?
    
    private var formatter: DateFormatter = {
        let form = DateFormatter()
        form.setLocalizedDateFormatFromTemplate("EEE MMM d at h:mm a")
        print("Brennan - date format: \(form.dateFormat)")
        return form
    }()
    
    var startTime: Date? {
        didSet {
            if let newDate = startTime {
                startTimeLabel.text = formatter.string(from: newDate)
            } else {
                startTimeLabel.text = "-"
            }
        }
    }
    
    var endTime: Date? {
        didSet {
            if let newDate = endTime {
                endTimeLabel.text = formatter.string(from: newDate)
            } else {
                endTimeLabel.text = "-"
            }
        }
    }
    
    private var startTimePickerVisible = false
    private var endTimePickerVisible = false
    
    private lazy var imagePicker = UIImagePickerController()
    private var didSelectImage = false
    
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set minimum times for start and end time pickers to the current time
        let today = Date()
        startTimePicker.minimumDate = today
        endTimePicker.minimumDate = today
        
        
        
    }
    
    
    
    // MARK: Picker methods
    
    @IBAction func startTimePickerChanged(_ sender: UIDatePicker) {
        startTime = sender.date
        endTimePicker.minimumDate = sender.date
        if endTime != nil {
            endTime = endTimePicker.date
        }
    }
    
    @IBAction func endTimePickerChanged(_ sender: UIDatePicker) {
        endTime = sender.date
    }
    
    
    
    
    
    
    
    
    
    // MARK: - Table View methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 2 {
            switch indexPath.row {
            case 0:
                // Tapped start time picker header
                startTimePickerVisible = !startTimePickerVisible
            case 2:
                // Tapped end time picker header
                endTimePickerVisible = !endTimePickerVisible
            default:
                return
            }
            
            tableView.beginUpdates()
            tableView.endUpdates()
            tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 2 {
            switch indexPath.row {
            case 1:
                // Start time picker
                return startTimePickerVisible ? 200 : 0
            case 3:
                // End time picker
                return endTimePickerVisible ? 200 : 0
            default:
                return super.tableView(tableView, heightForRowAt: indexPath)
            }
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    
    
    
    
    
    
    
    // MARK: Bar button item actions
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        dismissKeyboard()
        
        // Make sure everything is filled out, then save the new event to Firebase Storage and Database.
        
        guard let eventName = nameTextField.text, !eventName.isWhitespaceOrEmpty else {
            showErrorAlert(message: "Please enter a name for your event.")
            return
        }
        
        guard let eventLocation = locationTextField.text, !eventLocation.isWhitespaceOrEmpty else {
            showErrorAlert(message: "Please enter a location for your event.")
            return
        }
        
        guard let eventStartTime = startTime?.roundingDownToNearestMinute else {
            showErrorAlert(message: "Please select a start time for your event.")
            return
        }
        
        guard let eventEndTime = endTime?.roundingDownToNearestMinute else {
            showErrorAlert(message: "Please select an end time for your event.")
            return
        }
        
        guard eventStartTime < eventEndTime else {
            showErrorAlert(message: "Please ensure that your event's start time is earlier than its end time.")
            return
        }
        
        guard eventStartTime > Date() else {
            showErrorAlert(message: "Please ensure your event's start time is after the current date and time.")
            return
        }
        
        guard let eventSchedulerUID = Auth.auth().currentUser?.uid else {
            presentSignInVC()
            return
        }
        
        let eventImageDataFull = didSelectImage ? UIImageJPEGRepresentation(imageView.image!, StorageImageQuality.FULL) : nil
        let eventImageDataThumbnail = didSelectImage ? UIImageJPEGRepresentation(imageView.image!, StorageImageQuality.THUMBNAIL) : nil
        
        let eventDescription = descriptionTextView.text.isWhitespaceOrEmpty ? nil : descriptionTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var eventData: [String : Any] = [
            DBKeys.EVENT.name : eventName,
            DBKeys.EVENT.location : eventLocation,
            DBKeys.EVENT.startTime : eventStartTime.timeIntervalSince1970,
            DBKeys.EVENT.endTime : eventEndTime.timeIntervalSince1970,
            DBKeys.EVENT.schedulerUID : eventSchedulerUID
        ]
        eventData[DBKeys.EVENT.description] = eventDescription
        
        // Get the school ID, add it to the event data, and call the saveEventToFirebase function.
        DataService.instance.getSchoolIDForUser(withUID: Auth.auth().currentUser?.uid ?? "") { (currUserSchoolID) in
            guard let eventSchoolID = currUserSchoolID else {
                self.showErrorAlert(message: "Database error: Couldn't verify your school's ID.")
                return
            }
            
            eventData[DBKeys.EVENT.schoolID] = eventSchoolID
            self.saveEventToFirebase(eventData: eventData, eventImageDataFull: eventImageDataFull, eventImageDataThumbnail: eventImageDataThumbnail)
        }
    }
    
    
    
    
    // MARK: Image Picker Controller
    
    // User selected an event image.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let selectedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            imageView.image = selectedImage
            didSelectImage = true
        }
        picker.dismiss(animated: true)
    }
    
    // User canceled selecting an event image.
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    @IBAction func addImageTapped(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        // Does the user want to choose an existing image or create a new image?
        let prompt = UIAlertController(title: "Where is your event image?", message: nil, preferredStyle: .actionSheet)
        prompt.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { (action) in
            self.imagePicker.sourceType = .camera
            self.present(self.imagePicker, animated: true)
        }))
        prompt.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action) in
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true)
        }))
        prompt.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(prompt, animated: true)

    }
    
    
    
    
    
    
    // MARK: Text Field methods
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return true
    }
    
    
    
    
    // MARK: Text View methods
    
    @objc private func handleDismissKeyboardAccessoryTapped() {
        dismissKeyboard()
    }
    
    
    
    
    // MARK: Generating QR Codes
    
    private func generateQRCode(fromEventID eventID: String) -> UIImage? {
        guard let eventIDEncoded = eventID.data(using: .isoLatin1, allowLossyConversion: false) else {
            return nil
        }
        
        let qrFilter = CIFilter(name: "CIQRCodeGenerator", withInputParameters: ["inputMessage" : eventIDEncoded,
                                                                                 "inputCorrectionLevel" : "Q"])
        guard let outputCIImage = qrFilter?.outputImage, let outputCGImage = CIContext(options: nil).createCGImage(outputCIImage, from: outputCIImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: outputCGImage)
    }
    
    
    
    
    // MARK:
    
    private func saveEventToFirebase(eventData: [String : Any], eventImageDataFull: Data?, eventImageDataThumbnail: Data?) {
        
        let eventID = DataService.instance.REF_EVENTS.childByAutoId().key
        
        guard let qrImage = generateQRCode(fromEventID: eventID), let qrImageData = UIImageJPEGRepresentation(qrImage, StorageImageQuality.FULL) else {
            showErrorAlert(message: "There was a problem generating a QR code for the new event.")
            return
        }
        
        let uniqueID = UUID().uuidString
        
        // Upload the QR code image to Storage.
        let metadataQR = StorageMetadata()
        metadataQR.contentType = "image/jpeg"
        StorageService.instance.REF_QR_CODE_PICS.child(uniqueID).putData(qrImageData, metadata: metadataQR) { (metadata, error) in
            guard error == nil else {
                self.showErrorAlert(message: StorageService.instance.messageForStorageError(error! as NSError))
                return
            }
            
            guard let qrURL = metadata?.downloadURLs?[0].absoluteString else {
                self.showErrorAlert(message: "There was a problem saving the QR code to storage.")
                return
            }
            
            // QR code image upload complete. Upload the event image(s) if necessary.
            if eventImageDataFull != nil, eventImageDataThumbnail != nil {
                // Chose an event image.
                let metadataFull = StorageMetadata()
                metadataFull.contentType = "image/jpeg"
                
                StorageService.instance.REF_EVENT_PICS_FULL.child(uniqueID).putData(eventImageDataFull!, metadata: metadataFull) { (metadata, error) in
                    guard error == nil else {
                        self.showErrorAlert(message: StorageService.instance.messageForStorageError(error! as NSError))
                        return
                    }
                    
                    guard let imageURL = metadata?.downloadURLs?[0].absoluteString else {
                        self.showErrorAlert(message: "There was a problem saving the event image to storage.")
                        return
                    }
                    
                    let metadataThumbnail = StorageMetadata()
                    metadataThumbnail.contentType = "image/jpeg"
                    
                    StorageService.instance.REF_EVENT_PICS_THUMBNAIL.child(uniqueID).putData(eventImageDataThumbnail!, metadata: metadataThumbnail) { (metadata, error) in
                        guard error == nil else {
                            self.showErrorAlert(message: StorageService.instance.messageForStorageError(error! as NSError))
                            return
                        }
                        
                        guard let thumbnailURL = metadata?.downloadURLs?[0].absoluteString else {
                            self.showErrorAlert(message: "There was a problem saving the event image to storage.")
                            return
                        }
                        
                        // All storage uploads complete. Save the new event in the database.
                        var newEventData = eventData
                        newEventData[DBKeys.EVENT.qrCodeURL] = qrURL
                        newEventData[DBKeys.EVENT.imageURL] = imageURL
                        newEventData[DBKeys.EVENT.thumbnailURL] = thumbnailURL
                        
                        DataService.instance.createEvent(withID: eventID, eventData: newEventData) { (errorMessage) in
                            guard errorMessage == nil else {
                                self.showErrorAlert(message: errorMessage!)
                                return
                            }
                            print("Brennan - successfully created the new event!")
                            self.showSuccessAlert()
                        }
                    }
                }
            } else {
                // Didn't choose an event image.
                var newEventData = eventData
                newEventData[DBKeys.EVENT.qrCodeURL] = qrURL
                
                DataService.instance.createEvent(withID: eventID, eventData: newEventData) { (errorMessage) in
                    guard errorMessage == nil else {
                        self.showErrorAlert(message: errorMessage!)
                        return
                    }
                    print("Brennan - successfully created the new event!")
                    self.showSuccessAlert()
                }
            }
        }
    }
    
    
    
    
    private func showSuccessAlert() {
        let successAlert = UIAlertController(title: "Success!", message: "Successfully created the event.", preferredStyle: .alert)
        successAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (okAction) in
            self.dismiss(animated: true)
        }))
        present(successAlert, animated: true)
    }
    
    
    
    
    
    
    
    
    
    
    
}
