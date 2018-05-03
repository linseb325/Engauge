//
//  RoleRequestDetailsVC.swift
//  Engauge
//
//  Created by Brennan Linse on 5/2/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit

class RoleRequestDetailsVC: UIViewController {
    
    // MARK: Outlets
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    
    
    
    // MARK: Properties
    
    var notification: EngaugeNotification!
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateUI()
    }
    
    
    
    
    // MARK: Updating the UI
    
    private func updateUI() {
        // Retrieve and display the requester's profile image.
        StorageService.instance.getImageForUser(withUID: notification.senderUID, thumbnail: true) { (userImage) in
            if userImage != nil {
                self.imageView.image = userImage
            }
        }
        
        // Retrieve and display the requester's first + last name.
        DataService.instance.getNameForUser(withUID: notification.senderUID) { (userFullName) in
            if userFullName != nil {
                self.nameLabel.text = userFullName
            }
        }
        
        // Retrieve and display the requester's e-mail address.
        DataService.instance.getEmailAddressForUser(withUID: notification.senderUID) { (userEmail) in
            if userEmail != nil {
                self.emailLabel.text = userEmail
            }
        }
    }
    
    
    
    
    // MARK: Button Actions
    
    @IBAction func approveTapped(_ sender: UIButton) {
        showAreYouSureAlert(approve: true)
    }
    
    @IBAction func denyTapped(_ sender: UIButton) {
        showAreYouSureAlert(approve: false)
    }
    
    private func respondToRoleRequest(approve: Bool) {
        DataService.instance.performUpdatesForRoleRequestDecision(forNotificationWithID: notification.notificationID, senderUID: notification.senderUID, receiverUID: notification.receiverUID, approveUserForScheduler: approve) { (success) in
            
            guard success else {
                self.showErrorAlert(title: "Database Error", message: "Could not respond to the role request.", dismissHandler: { (okAction) in
                    if let navcon = self.navigationController {
                        navcon.popViewController(animated: true)
                    } else {
                        self.dismiss(animated: true)
                    }
                })
                return
            }
            
            self.showSuccessAlertAndDismiss(wasApproved: approve)
        }
    }
    
    
    
    
    // MARK: Alerts
    
    private func showSuccessAlertAndDismiss(wasApproved: Bool) {
        let successAlert = UIAlertController(title: "Success!", message: "\(wasApproved ? "Approved" : "Denied") this user's request for Scheduler status.", preferredStyle: .alert)
        successAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (okAction) in
            if let navcon = self.navigationController {
                navcon.popViewController(animated: true)
            } else {
                self.dismiss(animated: true)
            }
        }))
        present(successAlert, animated: true)
    }
    
    private func showAreYouSureAlert(approve: Bool) {
        let areYouSureAlert = UIAlertController(title: "Are you sure?", message: "Are you sure you'd like to \(approve ? "approve" : "deny") this user's request for Scheduler status?\(approve ? " The user will be able to schedule events and view user profiles." : "")", preferredStyle: .alert)
        areYouSureAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        areYouSureAlert.addAction(UIAlertAction(title: "\(approve ? "Approve" : "Deny")", style: .default, handler: { (yesAction) in
            self.respondToRoleRequest(approve: approve)
        }))
        present(areYouSureAlert, animated: true)
    }
    
}
