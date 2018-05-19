//
//  EditProfileVC.swift
//  Engauge
//
//  Created by Brennan Linse on 4/23/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//
//  PURPOSE: Change profile information.

import UIKit
import FirebaseStorage

class EditProfileVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    // MARK: Outlets
    
    @IBOutlet weak var imageView: UIImageView!
    
    
    @IBOutlet weak var stackViewForTextFields: UIStackView!
    @IBOutlet weak var firstNameTextField: UITextField! { didSet { firstNameTextField.delegate = self } }
    @IBOutlet weak var lastNameTextField: UITextField! { didSet { lastNameTextField.delegate = self } }
    private var activeTextField: UITextField? {
        for textField in stackViewForTextFields.arrangedSubviews {
            if textField.isFirstResponder, textField is UITextField {
                return textField as? UITextField
            }
        }
        return nil
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var containerView: UIView!
    
    
    // MARK: Properties
    
    var user: EngaugeUser!
    
    private lazy var imagePicker = UIImagePickerController()
    private var didChangeImage = false
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateUIForCurrentUser()
        requestKeyboardNotifications()
    }
    
    
    
    
    // MARK: Updating the UI
    
    private func updateUIForCurrentUser() {
        Storage.storage().reference(forURL: self.user.imageURL).getData(maxSize: 2 * 1024 * 1024) { (imageData, error) in
            guard error == nil, imageData != nil else {
                return
            }
            
            self.imageView.image = UIImage(data: imageData!)
        }
        
        firstNameTextField.text = self.user.firstName
        lastNameTextField.text = self.user.lastName
        
    }
    
    
    
    
    // MARK: Bar Button Item Actions
    
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        dismissKeyboard()
        
        // Error checking because first and last name are required fields
        guard let firstName = firstNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !firstName.isEmpty else {
            showErrorAlertWithResetDataOption(message: "Please type a first name or reset to your most recent saved name.") { (action) in
                self.firstNameTextField.text = self.user.firstName
            }
            return
        }
        
        guard let lastName = lastNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !lastName.isEmpty else {
            showErrorAlertWithResetDataOption(message: "Please type a last name or reset to your most recent saved name.") { (action) in
                self.lastNameTextField.text = self.user.lastName
            }
            return
        }
        
        let updates = [
            DBKeys.USER.firstName : firstName,
            DBKeys.USER.lastName : lastName
        ]
        
        let imageDataFull = didChangeImage ? UIImageJPEGRepresentation(imageView.image!, StorageImageQuality.FULL) : nil
        let imageDataThumbnail = didChangeImage ? UIImageJPEGRepresentation(imageView.image!, StorageImageQuality.THUMBNAIL) : nil
        
        saveChangesToFirebase(profileDataUpdates: updates, imageDataFull: imageDataFull, imageDataThumbnail: imageDataThumbnail)
    }
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismissKeyboard()
        self.dismiss(animated: true)
    }
    
    
    
    
    // MARK: Saving the changes to Firebase
    
    private func saveChangesToFirebase(profileDataUpdates: [String : Any], imageDataFull: Data? = nil, imageDataThumbnail: Data? = nil) {
        
        self.showLoadingUI(withSpinnerText: "Saving...")
        
        if imageDataFull != nil, imageDataThumbnail != nil {
            // User updated the image.
            
            var updates = profileDataUpdates
            
            let uniqueID = UUID().uuidString
            
            let metadataFull = StorageMetadata()
            metadataFull.contentType = "image/jpeg"
            
            // Upload the full image to storage.
            StorageService.instance.REF_PROFILE_PICS_FULL.child(uniqueID).putData(imageDataFull!, metadata: metadataFull) { (metadata, error) in
                guard error == nil, let imageURL = metadata?.downloadURLs?.first?.absoluteString else {
                    self.hideLoadingUI(completion: {
                        self.showErrorAlert(message: "There was a problem uploading your new profile image to storage.")
                    })
                    return
                }
                
                updates[DBKeys.USER.imageURL] = imageURL
                
                let metadataThumbnail = StorageMetadata()
                metadataThumbnail.contentType = "image/jpeg"
                
                // Upload the thumbnail image to storage.
                StorageService.instance.REF_PROFILE_PICS_THUMBNAIL.child(uniqueID).putData(imageDataThumbnail!, metadata: metadataThumbnail) { (metadata, error) in
                    guard error == nil, let thumbnailURL = metadata?.downloadURLs?.first?.absoluteString else {
                        self.hideLoadingUI(completion: {
                            self.showErrorAlert(message: "There was a problem uploading your new profile image to storage.")
                        })
                        return
                    }
                    
                    updates[DBKeys.USER.thumbnailURL] = thumbnailURL
                    
                    // Update the profile data in the database.
                    DataService.instance.updateUserData(updates, forUserWithUID: self.user.userID) { (errMsg) in
                        guard errMsg == nil else {
                            self.hideLoadingUI(completion: {
                                self.showErrorAlert(message: errMsg!)
                            })
                            return
                        }
                    }
                    
                    // Delete the old profile image from storage.
                    StorageService.instance.deleteImage(atURL: self.user.imageURL)
                    StorageService.instance.deleteImage(atURL: self.user.thumbnailURL)
                    
                    // All profile updates were successful.
                    self.hideLoadingUI(completion: {
                        self.showSuccessAlert(onDismiss: { (okAction) in
                            self.dismiss(animated: true)
                        })
                    })
                }
            }
        } else {
            // User didn't update the image.
            
            DataService.instance.updateUserData(profileDataUpdates, forUserWithUID: self.user.userID) { (errMsg) in
                guard errMsg == nil else {
                    self.hideLoadingUI(completion: {
                        self.showErrorAlert(message: errMsg!)
                    })
                    return
                }
                
                // All profile updates were successful.
                self.hideLoadingUI(completion: {
                    self.showSuccessAlert(onDismiss: { (okAction) in
                        self.dismiss(animated: true)
                    })
                })
            }
        }
    }
    
    
    
    
    // MARK: Picking an image
    
    
    @IBAction func profileImageTapped(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
        
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        // Does the user want to choose an existing image or create a new image?
        let prompt = UIAlertController(title: "Where is your new profile image?", message: nil, preferredStyle: .actionSheet)
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let selectedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            imageView.image = selectedImage
            didChangeImage = true
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    
    
    
    // MARK: Text Field methods
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return true
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
    
    
    
    
    // MARK: Keyboard Notifications
    
    private func requestKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow(_:)), name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    @objc private func handleKeyboardDidShow(_ notification: Notification) {
        guard let keyboardHeight = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height else {
            print("Brennan - couldn't get keyboard size")
            return
        }
        print("Brennan - got keyboard size")
        
        let contentInsets = UIEdgeInsetsMake(0, 0, keyboardHeight, 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
        
        var visibleRect = self.containerView.frame
        visibleRect.size.height -= keyboardHeight
        if let activeField = self.activeTextField, !visibleRect.contains(activeField.frame.origin) {
            scrollView.scrollRectToVisible(activeField.frame, animated: true)
        }
    }
    
    @objc private func handleKeyboardWillHide(_ notification: Notification) {
        let zeroContentInsets = UIEdgeInsets.zero
        scrollView.contentInset = zeroContentInsets
        scrollView.scrollIndicatorInsets = zeroContentInsets
    }
    
    
    
    
    // MARK: Deinitializer
    
    deinit {
        print("Deallocating an instance of EditProfileVC")
        NotificationCenter.default.removeObserver(self)
    }
    
    
}
