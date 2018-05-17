//
//  NewPrizeTVC.swift
//  Engauge
//
//  Created by Brennan Linse on 5/6/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseAuth

class NewPrizeTVC: UITableViewController, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    
    
    // MARK: Outlets
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField! { didSet { nameTextField.delegate = self } }
    
    // Price UI
    @IBOutlet weak var priceTextField: UITextField! {
        didSet {
            priceTextField.delegate = self
            
            let toolbarAccessory = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
            toolbarAccessory.barStyle = .default
            
            let cancelItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancelTappedFromPriceTF))
            let flexibleSpaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let doneItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(handleDoneTappedFromPriceTF))
            
            toolbarAccessory.setItems([cancelItem, flexibleSpaceItem, doneItem], animated: true)
            
            toolbarAccessory.sizeToFit()
            
            priceTextField.inputAccessoryView = toolbarAccessory
        }
    }
    @IBOutlet weak var priceStepper: UIStepper! {
        didSet {
            priceStepper.minimumValue = Double(Prize.minPrice)
            priceStepper.maximumValue = Double(Prize.maxPrice)
            priceStepper.value = Double(Prize.minPrice)
        }
    }
    
    // Quantity UI
    @IBOutlet weak var quantityTextField: UITextField! {
        didSet {
            quantityTextField.delegate = self
            
            let toolbarAccessory = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
            toolbarAccessory.barStyle = .default
            
            let cancelItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancelTappedFromQuantityTF))
            let flexibleSpaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let doneItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(handleDoneTappedFromQuantityTF))
            
            toolbarAccessory.setItems([cancelItem, flexibleSpaceItem, doneItem], animated: true)
            
            toolbarAccessory.sizeToFit()
            
            quantityTextField.inputAccessoryView = toolbarAccessory
        }
    }
    @IBOutlet weak var quantityStepper: UIStepper! {
        didSet {
            quantityStepper.minimumValue = Double(Prize.minQuantity)
            quantityStepper.maximumValue = Double(Prize.maxQuantity)
            quantityStepper.value = Double(Prize.minQuantity)
        }
    }
    
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
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleDismissKeyboardFromDescriptionTextView))
            dismissAccessory.addGestureRecognizer(tap)
            descriptionTextView.inputAccessoryView = dismissAccessory
        }
    }
    
    
    
    
    // MARK: Properties
    
    private var price = Prize.minPrice {
        didSet {
            updatePriceStepperValue()
            updatePriceTextFieldText()
        }
    }
    private var quantityAvailable = Prize.minQuantity {
        didSet {
            updateQuantityStepperValue()
            updateQuantityTextFieldText()
        }
    }
    
    private lazy var imagePicker = UIImagePickerController()
    private var didSelectImage = false
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsSelection = false
    }
    
    
    
    
    // MARK: Bar button item actions
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        dismissKeyboard()
        
        // Make sure everything is filled out, then save the new prize to Firebase Storage and Database.
        
        guard let prizeName = nameTextField.text, !prizeName.isWhitespaceOrEmpty else {
            showErrorAlert(message: "Please enter a name for this prize.")
            return
        }
        
        guard let priceText = priceTextField.text, !priceText.isEmpty, price == Int(priceText), price >= Prize.minPrice else {
            showErrorAlert(message: "How many points does it take to purchase this item? Please choose a price.")
            return
        }
        
        guard let quantityText = quantityTextField.text, !quantityText.isEmpty, quantityAvailable == Int(quantityText), quantityAvailable >= Prize.minQuantity else {
            showErrorAlert(message: "How many of these do you have? Please choose a quantity.")
            return
        }
        
        guard let descriptionText = descriptionTextView.text, !descriptionText.isWhitespaceOrEmpty else {
            showErrorAlert(message: "What are the benefits of this prize? How will students receive the prize after purchasing? Please type a description.")
            return
        }
        let prizeDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard didSelectImage else {
            showErrorAlert(message: "Please select an image for this prize.")
            return
        }
        
        guard let selectedImage = imageView.image, let prizeImageData = UIImageJPEGRepresentation(selectedImage, StorageImageQuality.THUMBNAIL) else {
            showErrorAlert(message: "There was an issue converting the prize image for storage.")
            return
        }
        
        var prizeData: [String : Any] = [
            DBKeys.PRIZE.name : prizeName,
            DBKeys.PRIZE.price : price,
            DBKeys.PRIZE.quantityAvailable : quantityAvailable,
            DBKeys.PRIZE.description : prizeDescription
        ]
        
        // Get the school ID, add it to the prize data, and call the saveEventToFirebase function.
        DataService.instance.getSchoolIDForUser(withUID: Auth.auth().currentUser?.uid ?? "no-curr-user") { (currUserSchoolID) in
            guard let prizeSchoolID = currUserSchoolID else {
                self.showErrorAlert(message: "Database error: Couldn't verify your school's ID.")
                return
            }
            
            prizeData[DBKeys.PRIZE.schoolID] = prizeSchoolID
            self.savePrizeToFirebase(prizeData: prizeData, prizeImageData: prizeImageData)
        }
    }
    
    
    
    
    // MARK: Image Picker Controller
    
    // User selected a prize image.
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
        let prompt = UIAlertController(title: "Where is your prize image?", message: nil, preferredStyle: .actionSheet)
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
    
    private func updatePriceTextFieldText() {
        priceTextField.text = "\(price)"
    }
    
    private func updateQuantityTextFieldText() {
        quantityTextField.text = "\(quantityAvailable)"
    }
    
    // Done editing price
    @objc private func handleDoneTappedFromPriceTF() {
        dismissKeyboard()
        enableSteppers()
        
        if let priceText = priceTextField.text, let validPriceTyped = Int(priceText) {
            if validPriceTyped < Prize.minPrice {
                price = Prize.minPrice
            } else if validPriceTyped > Prize.maxPrice {
                price = Prize.maxPrice
            } else {
                price = validPriceTyped
            }
        } else {
            // Just use the current value of price.
            updatePriceTextFieldText()
        }
    }
    
    // Canceled editing price
    @objc private func handleCancelTappedFromPriceTF() {
        dismissKeyboard()
        enableSteppers()
        
        updatePriceTextFieldText()
    }
    
    // Done editing quantity
    @objc private func handleDoneTappedFromQuantityTF() {
        dismissKeyboard()
        enableSteppers()
        
        if let quantityText = quantityTextField.text, let validQuantityTyped = Int(quantityText) {
            if validQuantityTyped < Prize.minQuantity {
                quantityAvailable = Prize.minQuantity
            } else if validQuantityTyped > Prize.maxQuantity {
                quantityAvailable = Prize.maxQuantity
            } else {
                quantityAvailable = validQuantityTyped
            }
        } else {
            // Just use the current value of quantityAvailable.
            updateQuantityTextFieldText()
        }
    }
    
    // Canceled editing quantity
    @objc private func handleCancelTappedFromQuantityTF() {
        dismissKeyboard()
        enableSteppers()
        
        updateQuantityTextFieldText()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        disableSteppers()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        enableSteppers()
    }
    
    
    
    
    // MARK: Stepper methods
    
    @IBAction func priceStepperChanged(_ sender: UIStepper) {
        let stepVal = Int(sender.value)
        
        if stepVal > Prize.maxPrice {
            price = Prize.maxPrice
        } else if stepVal < Prize.minPrice {
            price = Prize.minPrice
        } else {
            price = Int(sender.value)
        }

    }
    
    @IBAction func quantityStepperChanged(_ sender: UIStepper) {
        let stepVal = Int(sender.value)
        
        if stepVal > Prize.maxQuantity {
            quantityAvailable = Prize.maxQuantity
        } else if stepVal < Prize.minQuantity {
            quantityAvailable = Prize.minQuantity
        } else {
            quantityAvailable = Int(sender.value)
        }
        
    }
    
    /** Sets the stepper's value to self.price */
    private func updatePriceStepperValue() {
        priceStepper.value = Double(price)
    }
    
    /** Sets the stepper's value to self.quantity */
    private func updateQuantityStepperValue() {
        quantityStepper.value = Double(quantityAvailable)
    }
    
    private func disableSteppers() {
        priceStepper.isEnabled = false
        quantityStepper.isEnabled = false
    }
    
    private func enableSteppers() {
        priceStepper.isEnabled = true
        quantityStepper.isEnabled = true
    }
    
    
    
    
    // MARK: Text View methods
    
    // Done editing description
    @objc private func handleDismissKeyboardFromDescriptionTextView() {
        dismissKeyboard()
        enableSteppers()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        disableSteppers()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        enableSteppers()
    }
    
    
    
    
    // MARK: Saving to Firebase services
    
    private func savePrizeToFirebase(prizeData: [String : Any], prizeImageData: Data) {
        
        self.showLoadingUI(withSpinnerText: "Saving...")
        
        let prizeID = DataService.instance.REF_PRIZES.childByAutoId().key
        
        let uniqueID = UUID().uuidString
        
        // Upload the prize image to Storage.
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        StorageService.instance.REF_PRIZE_PICS.child(uniqueID).putData(prizeImageData, metadata: metadata) { (metadata, error) in
            guard error == nil else {
                self.hideLoadingUI(completion: {
                    self.showErrorAlert(message: StorageService.instance.messageForStorageError(error! as NSError))
                })
                return
            }
            
            guard let prizeImageURL = metadata?.downloadURL()?.absoluteString else {
                self.hideLoadingUI(completion: {
                    self.showErrorAlert(message: "There was a problem saving the prize image to storage.")
                })
                return
            }
            
            // Prize image upload complete. Save the prize data to the database.
            var newPrizeData = prizeData
            newPrizeData[DBKeys.PRIZE.imageURL] = prizeImageURL
            
            DataService.instance.createPrize(withID: prizeID, prizeData: newPrizeData) { (errMsg) in
                guard errMsg == nil else {
                    self.hideLoadingUI(completion: {
                        self.showErrorAlert(message: errMsg!)
                    })
                    return
                }
                
                // Successfully created the new prize.
                self.hideLoadingUI(completion: {
                    self.showSuccessAlert()
                })
            }
        }
    }
    
    
    
    
    // MARK: Success alert
    
    private func showSuccessAlert() {
        let successAlert = UIAlertController(title: "Success!", message: "Successfully created the prize.", preferredStyle: .alert)
        successAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (okAction) in
            self.dismiss(animated: true)
        }))
        present(successAlert, animated: true)
    }
    
    
    
    
    // MARK: Deinitializer
    
    deinit {
        print("Deallocating an instance of NewPrizeTVC")
    }
    
}
