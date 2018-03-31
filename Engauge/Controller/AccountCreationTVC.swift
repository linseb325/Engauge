//
//  AccountCreationTVC.swift
//  Engauge
//
//  Created by Brennan Linse on 3/5/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseAuth

class AccountCreationTVC: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    // MARK: Outlets
    
    @IBOutlet weak var firstNameTextField: UITextField! { didSet { firstNameTextField.delegate = self } }
    @IBOutlet weak var lastNameTextField: UITextField! { didSet { lastNameTextField.delegate = self } }
    @IBOutlet weak var selectSchoolLabel: UILabel!
    @IBOutlet weak var selectedSchoolLabel: UILabel!
    @IBOutlet weak var schoolPickerView: UIPickerView! {
        didSet {
            schoolPickerView.delegate = self
            schoolPickerView.dataSource = self
            schoolPickerView.isHidden = true
            schoolPickerView.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    @IBOutlet weak var emailAddressTextField: UITextField! { didSet { emailAddressTextField.delegate = self } }
    @IBOutlet weak var passwordTextField: UITextField! { didSet { passwordTextField.delegate = self } }
    @IBOutlet weak var confirmPasswordTextField: UITextField! { didSet { confirmPasswordTextField.delegate = self } }
    @IBOutlet weak var roleSegmentedControl: UISegmentedControl!
    @IBOutlet weak var profileImageView: UIImageView!
    
    
    
    // MARK: Properties
    
    private lazy var imagePicker = UIImagePickerController()
    private var schools = [School]()
    private var selectedSchool: School? {
        didSet {
            self.selectSchoolLabel.text = "School"
            self.selectedSchoolLabel.text = selectedSchool?.name ?? "[Error]"
        }
    }
    private var didSelectImage = false
    private var pickerVisible = false
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Read the list of schools from the database and put them into the array.
        DataService.instance.getAllSchools { (schools) in
            self.schools = schools
            self.schools.sort { $0.name < $1.name }
            self.schoolPickerView.reloadAllComponents()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        // Need to sign out before returning to the sign-in screen.
        // Sign out.
        do {
            print("Brennan - gonna try to sign out now in viewWillDisappear.")
            try Auth.auth().signOut()
        } catch let signOutError {
            print("Brennan - error signing out: \(signOutError.localizedDescription)")
        }
    }
    
    
    
    // MARK: Bar button item actions
    
    // User wants to cancel account creation.
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    // TODO: Show a spinner while saving the new user in Auth/Storage/Database.
    // User wants to submit the new account details.
    @IBAction func createButtonTapped(_ sender: UIBarButtonItem) {
        dismissKeyboard()
        
        // Typed a first name?
        guard let firstName = firstNameTextField.text, firstName != "" else {
            showErrorAlert(message: "First name is required.")
            return
        }
        
        // Typed a last name?
        guard let lastName = lastNameTextField.text, lastName != "" else {
            showErrorAlert(message: "Last name is required.")
            return
        }
        
        // Picked a school?
        guard let schoolPicked = self.selectedSchool else {
            showErrorAlert(message: "Please select your school.")
            return
        }
        
        // Typed an e-mail address?
        guard let email = emailAddressTextField.text, email != "" else {
            showErrorAlert(message: "School e-mail address is required.")
            return
        }
        
        // E-mail domain matches the school's domain?
        guard email.hasSuffix(schoolPicked.domain) else {
            showErrorAlert(message: "That's not a \(schoolPicked.name) e-mail address.")
            return
        }
        
        // Typed a password?
        guard let password = passwordTextField.text, password != "" else {
            showErrorAlert(message: "Password is required.")
            return
        }
        
        // Typed a confirmed password?
        guard let confirmedPassword = confirmPasswordTextField.text, confirmedPassword != "" else {
            showErrorAlert(message: "Please confirm your password.")
            return
        }
        
        // Both passwords match?
        guard password == confirmedPassword else {
            showErrorAlert(message: "Passwords don't match.")
            return
        }
        
        // Selected a role?
        let selectedRoleIndex = roleSegmentedControl.selectedSegmentIndex
        guard selectedRoleIndex != -1 else {
            showErrorAlert(message: "Please select a role.")
            return
        }
        
        // Selected a profile image?
        guard didSelectImage, let profileImage = self.profileImageView.image else {
            showErrorAlert(message: "Please select a profile image.")
            return
        }
        
        // PASSED CHECKS FOR USER INPUT ERROR
        
        // Make sure the image can be converted to data objects.
        guard let imageDataFull = UIImageJPEGRepresentation(profileImage, StorageImageQuality.FULL), let imageDataThumbnail = UIImageJPEGRepresentation(profileImage, StorageImageQuality.THUMBNAIL) else {
            showErrorAlert(message: "Error converting profile image.")
            return
        }
        
        // If the user wants to be a Scheduler, ask if he/she is sure before proceeding.
        if selectedRoleIndex == UserRole.scheduler.toInt {
            let areYouSureAlert = UIAlertController(title: "Are you sure?", message: "You're requesting Scheduler status. We'll notify your school's Admin, and he/she will need to approve your request before you can sign in. Continue?", preferredStyle: .alert)
            areYouSureAlert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { (action) in
                // Continue with Firebase sign-up actions, passing relevant information to a helper function.
                self.completeAccountCreationTasks(firstName: firstName, lastName: lastName, schoolPicked: schoolPicked, email: email, password: password, selectedRoleIndex: selectedRoleIndex, profileImage: profileImage, imageDataFull: imageDataFull, imageDataThumbnail: imageDataThumbnail)
            }))
            areYouSureAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                return
            }))
            self.present(areYouSureAlert, animated: true)
        } else {
            // Continue with Firebase sign-up actions without presenting the "are you sure" prompt.
            completeAccountCreationTasks(firstName: firstName, lastName: lastName, schoolPicked: schoolPicked, email: email, password: password, selectedRoleIndex: selectedRoleIndex, profileImage: profileImage, imageDataFull: imageDataFull, imageDataThumbnail: imageDataThumbnail)
        }
        
    }
    
    func completeAccountCreationTasks(firstName: String, lastName: String, schoolPicked: School, email: String, password: String, selectedRoleIndex: Int, profileImage: UIImage, imageDataFull: Data, imageDataThumbnail: Data) {
        
        // 1) Create the new user in Firebase Auth.
        AuthService.instance.createUser(email: email, password: password) { (errorMessage, user) in
            // Check for errors
            guard errorMessage == nil else {
                self.showErrorAlert(message: errorMessage!)
                return
            }
            guard let newUser = user else {
                self.showErrorAlert(message: "There was a problem creating the new user.")
                return
            }
            print("Brennan - created the user in Auth.")
            
            
            // 2) Save the profile image in Firebase Storage.
            let uniqueID = UUID().uuidString
            let metadataFull = StorageMetadata()
            metadataFull.contentType = "image/jpeg"
            StorageService.instance.REF_PROFILE_PICS_FULL.child(uniqueID).putData(imageDataFull, metadata: metadataFull) { (metadata, error) in
                // Checks for errors
                guard error == nil else {
                    self.showErrorAlert(message: StorageService.instance.messageForStorageError(error! as NSError))
                    return
                }
                guard let downloadURLFull = metadata?.downloadURLs?[0].absoluteString else {
                    self.showErrorAlert(message: "There was a problem uploading your profile image to storage.")
                    return
                }
                print("Brennan - uploaded the full image to storage.")
                
                
                // 3) Save the profile image thumbnail in Firebase Storage.
                let metadataThumbnail = StorageMetadata()
                metadataThumbnail.contentType = "image/jpeg"
                StorageService.instance.REF_PROFILE_PICS_THUMBNAIL.child(uniqueID).putData(imageDataThumbnail, metadata: metadataThumbnail) { (metadata, error) in
                    // Checks for errors
                    guard error == nil else {
                        self.showErrorAlert(message: StorageService.instance.messageForStorageError(error! as NSError))
                        return
                    }
                    guard let downloadURLThumbnail = metadata?.downloadURLs?[0].absoluteString else {
                        self.showErrorAlert(message: "There was a problem uploading your profile image to storage.")
                        return
                    }
                    print("Brennan - uploaded the thumbnail image to storage.")
                    
                    
                    // 4) Save the new user's info in the database.
                    var userData: [String : Any] = [
                        DBKeys.USER.emailAddress: email,
                        DBKeys.USER.firstName: firstName,
                        DBKeys.USER.imageURL: downloadURLFull,
                        DBKeys.USER.lastName: lastName,
                        DBKeys.USER.role: selectedRoleIndex,
                        DBKeys.USER.schoolID: schoolPicked.schoolID,
                        DBKeys.USER.thumbnailURL: downloadURLThumbnail
                    ]
                    
                    // Students and Schedulers get extra fields
                    switch selectedRoleIndex {
                    case UserRole.student.toInt:
                        userData[DBKeys.USER.pointBalance] = 0
                    case UserRole.scheduler.toInt:
                        userData[DBKeys.USER.approvedForScheduler] = false
                    default:
                        break
                    }
                    
                    DataService.instance.createUserInDatabase(uid: newUser.uid, userInfo: userData) { (errorMessage) in
                        // Check for errors
                        guard errorMessage == nil else {
                            self.showErrorAlert(message: errorMessage!)
                            return
                        }
                        
                        // If the user wants to be a a Scheduler, the school's Admin must be notified.
                        if userData[DBKeys.USER.role] as? Int == UserRole.scheduler.toInt {
                            print("Brennan - about to try to send a notification")
                            DataService.instance.sendRoleRequestNotification(fromUserWithUID: newUser.uid, forSchoolWithID: schoolPicked.schoolID) { (errorMessage) in
                                guard errorMessage == nil else {
                                    self.showErrorAlert(message: errorMessage!)
                                    return
                                }
                                print("Brennan - sent the Admin a notification.")
                            }
                        }
                        
                        print("Brennan - created the user in Database.")
                        
                        
                        // 5) Send a verification e-mail.
                        AuthService.instance.sendEmailVerification(toUser: newUser) { (errorMessage, user) in
                            guard errorMessage == nil else {
                                self.showErrorAlert(message: errorMessage!)
                                return
                            }
                            
                            // Verification e-mail was sent.
                            print("Brennan - sent verification e-mail.")
                            
                            // TODO: Sign the user out right away?
                            print("Brennan - all 5 account creation steps COMPLETE.")
                            
                            // Sign out.
                            do {
                                try Auth.auth().signOut()
                            } catch let signOutError {
                                print("Brennan - error signing out: \(signOutError.localizedDescription)")
                            }
                            
                            // Show the user a success message and instruct him/her to verify his/her e-mail address.
                            let successAlert = UIAlertController(title: "Success", message: "You're almost done! Check your inbox for a verification e-mail.", preferredStyle: .alert)
                            successAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                                self.dismiss(animated: true)
                            }))
                            self.present(successAlert, animated: true)
                        }
                    }
                }
            }
        }

        
    }
    
    
    
    // MARK: Picking a profile image
    
    // User wants to add a profile image
    @IBAction func addImageTapped(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        // Does the user want to choose an existing image or create a new image?
        let prompt = UIAlertController(title: "Where is your profile image?", message: nil, preferredStyle: .actionSheet)
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
    
    // User pressed cancel in the image picker
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    // User selected a profile image.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let selectedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            profileImageView.image = selectedImage
            didSelectImage = true
        }
        picker.dismiss(animated: true)
    }
    
    
    
    // MARK: Picker View Methods
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedSchool = self.schools[row]
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.schools.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.schools[row].name
    }
    
    
    
    // MARK: Showing and hiding the cell with the PickerView
    
    func showPickerViewCell() {
        self.pickerVisible = true
        tableView.beginUpdates()
        tableView.endUpdates()
        UIView.animate(withDuration: 0.25, animations: {
            self.schoolPickerView.alpha = 1.0
        },  completion: { (finished) in
            self.schoolPickerView.isHidden = false
        })
    }
    
    func hidePickerViewCell() {
        self.pickerVisible = false
        tableView.beginUpdates()
        tableView.endUpdates()
        UIView.animate(withDuration: 0.25, animations: {
            self.schoolPickerView.alpha = 0.0
        }, completion: { (finished) in
            self.schoolPickerView.isHidden = true
        })
    }
    
    
    
    // MARK: Table View methods
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 1 && indexPath.section == 1 {
            return self.pickerVisible ? 150.0 : 0.0
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == 0 {
            if pickerVisible {
                hidePickerViewCell()
            } else {
                showPickerViewCell()
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    
    // MARK: Text Field Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return true
    }
}
