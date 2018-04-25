//
//  EditEventTVC.swift
//  Engauge
//
//  Created by Brennan Linse on 4/7/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
import Firebase

class EditEventTVC: UITableViewController, UIPickerViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
    
    var event: Event!
    var editedEvent: Event?
    
    private var formatter: DateFormatter = {
        let form = DateFormatter()
        form.setLocalizedDateFormatFromTemplate("EEE MMM d at h:mm a")
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
    private var didChangeImage = false
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Populate the UI with the event's existing data.
        if let eventImageURL = event.imageURL {
            Storage.storage().reference(forURL: eventImageURL).getData(maxSize: 2 * 1024 * 1024) { (data, error) in
                if error == nil, data != nil {
                    let eventImage = UIImage(data: data!)
                    self.imageView.image = eventImage
                }
            }
        }
        
        nameTextField.text = event.name
        locationTextField.text = event.location
        descriptionTextView.text = event.description
        
        startTimePicker.date = event.startTime
        startTime = startTimePicker.date
        endTimePicker.date = event.endTime
        endTime = endTimePicker.date
        
        updateMinimumDatesForTimePickers()
        
        
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
    
    
    
    
    // MARK: Picker methods
    
    @IBAction func startTimePickerChanged(_ sender: UIDatePicker) {
        print("startTimePickerChanged")
        startTime = sender.date
        
        updateMinimumDatesForTimePickers()
        
        // Update endTime because the endTimePicker's value might have changed after updating the minimum dates.
        if endTime != nil {
            endTime = endTimePicker.date
        }
    }
    
    @IBAction func endTimePickerChanged(_ sender: UIDatePicker) {
        endTime = sender.date
    }
    
    private func resetTimePickersToOriginalTimes() {
        startTimePicker.setDate(self.event.startTime, animated: true)
        startTime = startTimePicker.date                    // Updates the model too, if necessary.
        endTimePicker.setDate(self.event.endTime, animated: true)
        endTime = endTimePicker.date                        // Updates the model too, if necessary.
    }
    
    private func updateMinimumDatesForTimePickers() {
        startTimePicker.minimumDate = Date()
        startTime = startTimePicker.date                    // Updates the model too, if necessary.
        endTimePicker.minimumDate = startTimePicker.date
        endTime = endTimePicker.date                        // Updates the model too, if necessary.
    }
    
    
    
    
    // MARK: Bar button item actions
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        dismissKeyboard()
        
        // First, check that the input is valid and all required fields are filled out.
        guard let eventName = nameTextField.text, !eventName.isWhitespaceOrEmpty else {
            showErrorAlertWithResetDataOption(message: "Please enter a name for your event or reset the field to the event's original name.") { (resetAction) in
                self.nameTextField.text = self.event.name
            }
            return
        }
        
        guard let eventLocation = locationTextField.text, !eventLocation.isWhitespaceOrEmpty else {
            showErrorAlertWithResetDataOption(message: "Please enter a location for your event or reset the field to the event's original location.") { (resetAction) in
                self.locationTextField.text = self.event.location
            }
            return
        }
        
        guard let eventStartTime = startTime?.roundingDownToNearestMinute else {
            showErrorAlertWithResetDataOption(message: "Please select a start time for your event or reset to the event's original start time.") { (resetAction) in
                self.startTimePicker.setDate(self.event.startTime, animated: true)
                self.startTime = self.startTimePicker.date
                self.updateMinimumDatesForTimePickers()
            }
            return
        }
        
        guard let eventEndTime = endTime?.roundingDownToNearestMinute else {
            showErrorAlertWithResetDataOption(message: "Please select an end time for your event or reset to the event's original end time.") { (resetAction) in
                self.endTimePicker.setDate(self.event.endTime, animated: true)
                self.endTime = self.endTimePicker.date
                self.updateMinimumDatesForTimePickers()
            }
            return
        }
        
        guard eventStartTime < eventEndTime else {
            // Should never happen if the picker minimum dates are enforced correctly.
            showErrorAlertWithResetDataOption(message: "Please ensure that your event's start time is earlier than its end time or reset to the event's original start and end times.") { (resetAction) in
                self.resetTimePickersToOriginalTimes()
                self.updateMinimumDatesForTimePickers()
            }
            return
        }
        
        guard eventStartTime > Date() else {
            showErrorAlertWithResetDataOption(message: "Please ensure that your event's start time is after the current date and time or reset to the event's original start time.") { (resetAction) in
                self.startTimePicker.setDate(self.event.startTime, animated: true)
                self.startTime = self.startTimePicker.date
                self.updateMinimumDatesForTimePickers()
            }
            return
        }
        
        let eventImageDataFull = didChangeImage ? UIImageJPEGRepresentation(imageView.image!, StorageImageQuality.FULL) : nil
        let eventImageDataThumbnail = didChangeImage ? UIImageJPEGRepresentation(imageView.image!, StorageImageQuality.THUMBNAIL) : nil
        
        let eventDescription = descriptionTextView.text.isWhitespaceOrEmpty ? nil : descriptionTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var eventData: [String : Any] = [
            DBKeys.EVENT.name : eventName,
            DBKeys.EVENT.location : eventLocation,
            DBKeys.EVENT.startTime : eventStartTime.timeIntervalSince1970,
            DBKeys.EVENT.endTime : eventEndTime.timeIntervalSince1970,
        ]
        eventData.updateValue(eventDescription, forKey: DBKeys.EVENT.description)
        
        // Save changes to Firebase via a helper function.
        saveChangesToFirebase(eventDataUpdates: eventData, eventImageDataFull: eventImageDataFull, eventImageDataThumbnail: eventImageDataThumbnail)
    }
    
    private func saveChangesToFirebase(eventDataUpdates: [String : Any], eventImageDataFull: Data?, eventImageDataThumbnail: Data?) {
        
        if eventImageDataFull != nil, eventImageDataThumbnail != nil {
            // Changed the image.
            
            var updates = eventDataUpdates
            
            let uniqueID = UUID().uuidString
            
            let metadataFull = StorageMetadata()
            metadataFull.contentType = "image/jpeg"
            
            // 1) Upload full image to storage.
            StorageService.instance.REF_EVENT_PICS_FULL.child(uniqueID).putData(eventImageDataFull!, metadata: metadataFull) { (metadata, error) in
                guard error == nil, let imageURL = metadata?.downloadURL()?.absoluteString else {
                    self.showErrorAlert(message: "There was a problem uploading the new event image to storage.")
                    return
                }
                
                updates[DBKeys.EVENT.imageURL] = imageURL
                
                let metadataThumbnail = StorageMetadata()
                metadataThumbnail.contentType = "image/jpeg"
                
                // 2) Upload thumbnail image to storage.
                StorageService.instance.REF_EVENT_PICS_THUMBNAIL.child(uniqueID).putData(eventImageDataThumbnail!, metadata: metadataThumbnail) { (metadata, error) in
                    guard error == nil, let thumbnailURL = metadata?.downloadURL()?.absoluteString else {
                        self.showErrorAlert(message: "There was a problem uploading the new event image to storage.")
                        return
                    }
                    
                    updates[DBKeys.EVENT.thumbnailURL] = thumbnailURL
                    
                    // 3) Update the event data in the database.
                    DataService.instance.updateEventData(updates, forEventWithID: self.event.eventID) { (errorMessage) in
                        guard errorMessage == nil else {
                            self.showErrorAlert(message: errorMessage!)
                            return
                        }
                        
                        // If there was an old event image, delete it from Firebase Storage.
                        if self.event.imageURL != nil, self.event.thumbnailURL != nil {
                            StorageService.instance.deleteImage(atURL: self.event.imageURL!)
                            StorageService.instance.deleteImage(atURL: self.event.thumbnailURL!)
                        }
                        
                        // All Firebase updates were successful.
                        // Now, get the edited event from the database and unwind so we can update the previous screen.
                        self.setEditedEventAndUnwind()
                    }
                }
            }
        } else {
            // Didn't change the image. Just update the event data in the database.
            DataService.instance.updateEventData(eventDataUpdates, forEventWithID: self.event.eventID) { (errorMessage) in
                guard errorMessage == nil else {
                    self.showErrorAlert(message: errorMessage!)
                    return
                }
                
                // All Firebase updates (just database updates in this case) were successful.
                // Now, get the edited event from the database and unwind so we can update the previous screen.
                self.setEditedEventAndUnwind()
            }
        }
    }
    
    private func setEditedEventAndUnwind() {
        DataService.instance.getEvent(withID: self.event.eventID) { (event) in
            if event != nil {
                self.editedEvent = event!
            }
            
            self.showSuccessAlert(onDismiss: { (okAction) in
                self.performSegue(withIdentifier: "unwindFromEditEventTVC", sender: nil)
            })
        }
    }
    
    
    
    
    // MARK: Image Picker Controller
    
    // User selected an event image.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let selectedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            imageView.image = selectedImage
            didChangeImage = true
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
    
    
    
    
    // MARK: Success alert
    
    private func showSuccessAlert(onDismiss: ((UIAlertAction) -> Void)?) {
        let successAlert = UIAlertController(title: "Success!", message: "Successfully saved your changes.", preferredStyle: .alert)
        successAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: onDismiss))
        present(successAlert, animated: true)
    }
    
    
    
    
    // MARK: Data validation error alert
    
    private func showErrorAlertWithResetDataOption(message: String, resetActionTitle: String? = nil, resetDataHandler: @escaping (UIAlertAction) -> Void) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        let resetDataAction = UIAlertAction(title: (resetActionTitle ?? "Reset Info"), style: .destructive, handler: resetDataHandler)
        alert.addAction(resetDataAction)
        present(alert, animated: true)
    }
    
}
