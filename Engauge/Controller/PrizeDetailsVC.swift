//
//  PrizeDetailsVC.swift
//  Engauge
//
//  Created by Brennan Linse on 5/5/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class PrizeDetailsVC: UIViewController {
    
    // MARK: Outlets
    
    @IBOutlet weak var topStackView: UIStackView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var quantityAvailableLabel: UILabel!
    @IBOutlet weak var redeemButton: UIButton!
    @IBOutlet weak var redeemButtonContainerStackView: UIStackView!
    @IBOutlet weak var descriptionBodyLabel: UILabel!
    @IBOutlet weak var descriptionStackView: UIStackView!
    
    @IBOutlet weak var topMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var containerView: UIView!
    
    
    
    
    // MARK: Properties
    
    var prizeID: String!
    private var prize: Prize?
    
    // Database Observer Stuff
    private var prizeDataRef: DatabaseReference?
    private var prizeDataChangedHandle: DatabaseHandle?
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        attachDatabaseObserver()
    }
    
    
    
    
    // MARK: Configuring the UI
    
    /** Does NOT show nor hide the redeem button. That is the responsibility of configureRoleBasedUI(). */
    private func updateUIForCurrentPrize() {
        guard let currPrize = self.prize else {
            return
        }
        
        // Get the prize image
        if let cacheImage = PrizeListTVC.imageCache.object(forKey: currPrize.imageURL as NSString) {
            self.imageView.image = cacheImage
        } else {
            StorageService.instance.getImageForPrize(withID: currPrize.prizeID) { (prizeImage) in
                if prizeImage != nil {
                    self.imageView.image = prizeImage
                    PrizeListTVC.imageCache.setObject(prizeImage!, forKey: currPrize.imageURL as NSString)
                }
            }
        }
        
        self.nameLabel.text = currPrize.name
        self.priceLabel.text = "\(currPrize.price) point\(currPrize.price > 1 ? "s" : "")"
        
        self.redeemButton.setTitle("REDEEM \(currPrize.price) POINT\(currPrize.price > 1 ? "S" : "")", for: .normal)
        
        let unitsAvailable = currPrize.quantityAvailable > 0
        
        if unitsAvailable {
            self.quantityAvailableLabel.text = "(\(currPrize.quantityAvailable) available)"
            self.quantityAvailableLabel.textColor = .black
        } else {
            self.quantityAvailableLabel.text = "(SOLD OUT)"
            self.quantityAvailableLabel.textColor = .red
        }
        
        self.descriptionBodyLabel.text = currPrize.description
        
        resizeContainerAndScrollViewsToFitContentIfNecessary()
    }
    
    /**
     - Current user's role? [edit button, redeem button]
     */
    private func configureRoleBasedUI() {
        
        guard let currUserUID = Auth.auth().currentUser?.uid else {
            // TODO: Nobody is signed in!
            return
        }
        
        DataService.instance.getRoleForUser(withUID: currUserUID) { (roleNum) in
            guard let currUserRoleNum = roleNum, let currPrize = self.prize else {
                return
            }
            
            let unitsAvailable = currPrize.quantityAvailable > 0
            
            switch currUserRoleNum {
            case UserRole.student.toInt:
                // I can buy this, but not edit
                if unitsAvailable {
                    self.showRedeemButton()
                } else {
                    self.hideRedeemButton()
                }
                self.navigationItem.setRightBarButtonItems(nil, animated: true)
                
            case UserRole.scheduler.toInt:
                // I can view this, but not buy or edit
                self.hideRedeemButton()
                self.navigationItem.setRightBarButtonItems(nil, animated: true)
                
            case UserRole.admin.toInt:
                // I can edit or delete this, but not buy
                self.hideRedeemButton()
                self.setUpEditAndDeleteUI()
                
            default:
                break
            }
            
            self.resizeContainerAndScrollViewsToFitContentIfNecessary()
        }
    }
    
    /** Resizes both the container view and the scroll view. Only called from updateUIForCurrentPrize() and configureRoleBasedUI().
     - Sizes the scroll view to fit its content.
     - Lays out the main view/subviews if needed.
     */
    func resizeContainerAndScrollViewsToFitContentIfNecessary() {
        
        self.view.layoutIfNeeded()
        
        let lowPoint = CGPoint(x: 0, y: descriptionStackView.frame.maxY + topMarginConstraint.constant)
        let requiredHeight = CGPoint.verticalDistanceBetween(point: self.containerView.bounds.origin, andPoint: lowPoint)
        
        self.containerViewHeightConstraint.constant = max(requiredHeight, scrollView.bounds.height)
        
        self.view.layoutIfNeeded()
        self.scrollView.sizeToFit()
        self.view.layoutIfNeeded()
    }

    private func hideRedeemButton() {
        redeemButtonContainerStackView.frame.size.height = 0
        redeemButton.isHidden = true
    }
    
    private func showRedeemButton() {
        redeemButton.isHidden = false
        redeemButtonContainerStackView.sizeToFit()
    }
    
    /** Sets the right bar buttons to Edit and Delete this prize. */
    private func setUpEditAndDeleteUI() {
        var barButtons = [UIBarButtonItem]()
        let deleteButton = UIBarButtonItem(barButtonSystemItem: .trash , target: self, action: #selector(self.handleDeleteButtonTapped))
        deleteButton.tintColor = UIColor.red
        barButtons.append(deleteButton)
        
        let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(self.handleEditTapped))
        barButtons.insert(contentsOf: [editButton, space], at: 0)
        
        self.navigationItem.setRightBarButtonItems(barButtons, animated: true)
    }

    
    
    
    
    // MARK: Database Observers
    
    /** Sets prizeDataRef. */
    private func attachDatabaseObserver() {
        removeDatabaseObserverIfNecessary()
        prizeDataRef = DataService.instance.REF_PRIZES.child(prizeID)
        
        prizeDataChangedHandle = prizeDataRef?.observe(.value) { (snapshot) in
            if let changedPrizeData = snapshot.value as? [String : Any], let changedPrize = DataService.instance.prizeFromSnapshotValues(changedPrizeData, withID: snapshot.key) {
                self.prize = changedPrize
                self.updateUIForCurrentPrize()
                self.configureRoleBasedUI()
            }
        }
    }
    
    private func removeDatabaseObserverIfNecessary() {
        if prizeDataChangedHandle != nil {
            prizeDataRef?.removeObserver(withHandle: prizeDataChangedHandle!)
            prizeDataChangedHandle = nil
        }
    }
    
    
    
    
    // MARK: Button Actions
    
    @objc private func handleEditTapped() {
        if let currPrize = prize {
            performSegue(withIdentifier: "toEditPrizeTVC", sender: currPrize)
        }
    }
    
    /**
     - Performs these error checks:
            - Is self.prize set to something?
            - Are there any of these left?
            - Do I have enough points to buy this?
     - If all error checks are passed, calls self.showAreYouSureAlert().
     */
    @IBAction func redeemTapped(_ sender: UIButton) {
        guard let currPrize = self.prize else {
            return
        }
        
        // Are there any of these left?
        guard currPrize.quantityAvailable > 0 else {
            showErrorAlert(message: "This prize has sold out. Sorry!")
            return
        }
        
        guard let currUserUID = Auth.auth().currentUser?.uid else {
            showErrorAlert(message: "Couldn't verify your user credentials.")
            return
        }
        
        DataService.instance.getPointBalanceForUser(withUID: currUserUID) { (balance) in
            guard let currUserPointBalance = balance else {
                self.showErrorAlert(message: "Couldn't verify your current point balance.")
                return
            }
            
            // Do I have enough points to buy this?
            guard (currUserPointBalance - currPrize.price) >= 0 else {
                self.showErrorAlert(message: "You don't have enough points to purchase this prize. Go attend some events!")
                return
            }
            
            self.showAreYouSureAlert()
        }
    }
    
    @objc private func handleDeleteButtonTapped() {
        let areYouSureAlertDelete = UIAlertController(title: "Delete prize?", message: "Are you sure you'd like to delete this prize? You can't undo this operation!", preferredStyle: .alert)
        areYouSureAlertDelete.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        areYouSureAlertDelete.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (deleteAction) in
            
            guard let currPrize = self.prize else {
                self.showErrorAlert(message: "Couldn't verify the prize info. Did not delete the prize.")
                return
            }
            
            // Delete the prize from the school's list of prizes.
            DataService.instance.deletePrizeFromSchoolList(prizeToDelete: currPrize) { (errMsg) in
                guard errMsg == nil else {
                    self.showErrorAlert(message: errMsg!)
                    return
                }
                
                // Successfully deleted the prize from the list.
                self.showSuccessAlert(withMessage: "Deleted this prize from your school's list of available prizes.")
            }
        }))
        present(areYouSureAlertDelete, animated: true)
    }
    
    
    
    
    // MARK: Processing the Transaction
    
    private func completePrizePurchaseIfPossible() {
        guard let currPrize = self.prize else {
            showErrorAlert(message: "Couldn't verify this prize's information. Did not complete the transaction.")
            return
        }
        
        guard let currUserUID = Auth.auth().currentUser?.uid else {
            showErrorAlert(message: "Couldn't verify your user credentials. Did not complete the transaction.")
            return
        }
        
        DataService.instance.getSchoolIDForUser(withUID: currUserUID) { (schoolID) in
            guard let currUserSchoolID = schoolID else {
                self.showErrorAlert(message: "Couldn't verify your school's information. Did not complete the transaction.")
                return
            }
            
            DataService.instance.performTransaction(withPointValue: -currPrize.price, toUserWithUID: currUserUID, forSchoolWithID: currUserSchoolID, forPrizeWithID: currPrize.prizeID) { (transactionSuccessful) in
                if transactionSuccessful {
                    // Completed the transaction.
                    self.showSuccessAlert(withMessage: "Redeemed your points for this prize.")
                } else {
                    // Couldn't complete the transaction.
                    self.showErrorAlert(title: "Database Error", message: "Could not complete the transaction. Try again.")
                }
            }
        }
    }
    
    
    
    
    // MARK: Alerts
    
    /** Default onDismiss handler is to dismiss the current VC. */
    private func showSuccessAlert(withMessage message: String, onDismiss: ((UIAlertAction) -> Void)? = nil) {
        let successAlert = UIAlertController(title: "Success!", message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default,
                                     handler: onDismiss ?? { (okAction) in
                                        // Dismiss this screen
                                        if let navcon = self.navigationController {
                                            navcon.popViewController(animated: true)
                                        } else {
                                            self.dismiss(animated: true)
                                        }
            })
        successAlert.addAction(okAction)
        present(successAlert, animated: true)
    }
    
    private func showAreYouSureAlert() {
        guard let currPrize = self.prize else {
            showErrorAlert(message: "There was an issue verifying this prize's information.")
            return
        }
        
        let areYouSureAlert = UIAlertController(title: "Are you sure?", message: "Are you sure you would like to redeem \(currPrize.price) point\(currPrize.price > 1 ? "s" : "") for \(currPrize.name)?", preferredStyle: .alert)
        areYouSureAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        areYouSureAlert.addAction(UIAlertAction(title: "Redeem", style: .default, handler: { (redeemAction) in
            self.completePrizePurchaseIfPossible()
        }))
        present(areYouSureAlert, animated: true)
    }
    
    
    
    
    // MARK: Deinitializer
    
    deinit {
        removeDatabaseObserverIfNecessary()
    }
    
}
