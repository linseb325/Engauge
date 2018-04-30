//
//  ManualTransactionVC.swift
//  Engauge
//
//  Created by Brennan Linse on 4/29/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ManualTransactionVC: UIViewController, UITextFieldDelegate {
    
    // MARK: Outlets
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var arrowIconLabel: UILabel!
    
    @IBOutlet weak var numPointsSignSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var numPointsStepper: UIStepper! {
        didSet {
            numPointsStepper.minimumValue = Double(ManualTransaction.minPoints)
            numPointsStepper.maximumValue = Double(ManualTransaction.maxPoints)
            numPointsStepper.value = Double(ManualTransaction.minPoints)
        }
    }
    @IBOutlet weak var numPointsTextField: UITextField! {
        didSet {
            numPointsTextField.delegate = self
            
            let dismissAccessory = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
            dismissAccessory.backgroundColor = UIColor.lightGray
            
            let label = UILabel(frame: dismissAccessory.bounds)
            label.textColor = UIColor.white
            label.textAlignment = .center
            let textAttributes: [NSAttributedStringKey : Any] = [.font : UIFont(name: "Avenir", size: 18) as Any]
            let dismissText = NSAttributedString(string: "Dismiss keyboard", attributes: textAttributes)
            label.attributedText = dismissText
            dismissAccessory.addSubview(label)
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleDismissKeyboardAccessoryTapped))
            dismissAccessory.addGestureRecognizer(tap)
            numPointsTextField.inputAccessoryView = dismissAccessory
        }
    }
    
    
    // MARK: Properties
    
    var canChangeSelectedUser = true
    
    private var didSelectAUser: Bool { return selectedUser != nil }
    var selectedUser: EngaugeUser?
    
    private var numPoints = ManualTransaction.minPoints {
        didSet {
            updateStepperValue()
            updateNumPointsTextFieldText()
            updateNumPointsTextFieldColor()
        }
    }
    
    private var selectedUserBalanceRef: DatabaseReference?
    private var userBalanceChangedHandle: DatabaseHandle?
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arrowIconLabel.isHidden = !canChangeSelectedUser
        
        if selectedUser != nil {
            updateUIForSelectedUser()
            attachBalanceObserver()
        }
        
        updateStepperValue()
        updateNumPointsTextFieldText()
        updateNumPointsTextFieldColor()
    }
    
    
    
    
    // MARK: Updating UI
    
    private func updateUIForSelectedUser() {
        guard didSelectAUser else {
            nameLabel.text = "Select a user..."
            balanceLabel.text = " "
            imageView.image = UIImage(named: "avatar-square-gray")
            return
        }
        
        StorageService.instance.getImageForUser(withUID: selectedUser!.userID, thumbnail: true) { (userImage) in
            self.imageView.image = userImage
        }
        
        nameLabel.text = selectedUser?.fullName
        updateBalanceLabel()
    }
    
    private func updateBalanceLabel() {
        balanceLabel.text = "Balance: \(selectedUser?.pointBalance ?? 0) points"
    }
    /** Updates the text field's text based on self.numPoints */
    private func updateNumPointsTextFieldText() {
        numPointsTextField.text = "\(numPoints)"
    }
    
    /** Updates the text field's text color based on the chosen sign */
    private func updateNumPointsTextFieldColor() {
        
        switch numPointsSignSegmentedControl.selectedSegmentIndex {
            
        case 0:
            // Add
            numPointsTextField.textColor = .green
            
        case 1:
            // Subtract
            numPointsTextField.textColor = .red
            
        default:
            break
        }
    }
    
    /** Updates the stepper's value based on self.numPoints */
    private func updateStepperValue() {
        numPointsStepper.value = Double(numPoints)
    }
    
    
    
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toProfileListVC":
            if let profileListScreen = segue.destination.contentsViewController as? ProfileListVC {
                profileListScreen.adminIsChoosingForManualTransaction = true
            }
        default:
            break
        }
    }
    
    @IBAction func unwindFromProfileDetailsVC(sender: UIStoryboardSegue) {
        if let sourceVC = sender.source as? ProfileDetailsVC, let pickedUser = sourceVC.thisProfileUser {
            self.selectedUser = pickedUser
            self.updateUIForSelectedUser()
            self.attachBalanceObserver()
        }
    }
    
    
    
    
    // MARK: Button and Gesture Recognizer Actions
    
    @IBAction func selectUserTapped(_ sender: UITapGestureRecognizer) {
        print("Select user tapped")
        if canChangeSelectedUser {
            performSegue(withIdentifier: "toProfileListVC", sender: nil)
        }
    }
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    @IBAction func applyTapped(_ sender: UIBarButtonItem) {
        // TODO: Check for errors and try to complete the transaction. On success, display a success message and dismiss this screen.
        print("Apply tapped")
    }
    
    
    
    
    // MARK: Stepper Updates
    
    @IBAction func stepperChanged(_ sender: UIStepper) {
        print("Stepper value changed")
        let stepVal = Int(sender.value)
        
        if stepVal > ManualTransaction.maxPoints {
            numPoints = ManualTransaction.maxPoints
        } else if stepVal < ManualTransaction.minPoints {
            numPoints = ManualTransaction.minPoints
        } else {
            numPoints = Int(sender.value)
        }
    }
    
    
    
    
    // MARK: Segmented Control Updates
    
    @IBAction func signSegmentedControlChanged(_ sender: UISegmentedControl) {
        updateNumPointsTextFieldColor()
    }
    
    
    
    
    // MARK: Text Field Delegate
    
    @objc private func handleDismissKeyboardAccessoryTapped() {
        dismissKeyboard()
        if let tfText = numPointsTextField.text, let validNumTyped = Int(tfText) {
            
            switch validNumTyped {
                
            case ..<ManualTransaction.minPoints:
                // Typed number too small!
                self.numPoints = ManualTransaction.minPoints
                
            case (ManualTransaction.maxPoints+1)...:
                // Typed number too large!
                self.numPoints = ManualTransaction.maxPoints
                
            default:
                // Typed number in range.
                self.numPoints = validNumTyped
            }
            
        } else {
            updateNumPointsTextFieldText()
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        numPointsStepper.isEnabled = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        numPointsStepper.isEnabled = true
    }
    
    
    
    
    // MARK: Database Observers
    
    /**
     Removes any existing observer/handle.
     Sets the database reference.
     Attaches a balance observer that updates the displayed balance whenever the selected user's balance changes.
    */
    private func attachBalanceObserver() {
        guard didSelectAUser else {
            return
        }
        removeBalanceObserverIfNecessary()
        self.selectedUserBalanceRef = DataService.instance.REF_USERS.child(selectedUser!.userID).child(DBKeys.USER.pointBalance)
        self.userBalanceChangedHandle = selectedUserBalanceRef?.observe(.value) { (snapshot) in
            if let updatedBalance = snapshot.value as? Int {
                self.selectedUser?.pointBalance = updatedBalance
                self.updateBalanceLabel()
            }
        }
        
    }
    
    private func removeBalanceObserverIfNecessary() {
        if self.userBalanceChangedHandle != nil {
            self.selectedUserBalanceRef?.removeObserver(withHandle: self.userBalanceChangedHandle!)
            self.userBalanceChangedHandle = nil
        }
    }

    
    
    
    
    
    
    
    
    
    deinit {
        removeBalanceObserverIfNecessary()
    }
}
