//
//  ProfileDetailsVC.swift
//  Engauge
//
//  Created by Brennan Linse on 4/16/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseStorage

class ProfileDetailsVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Outlets
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    
    @IBOutlet weak var signOutButton: UIButton!
    
    @IBOutlet weak var recentTransactionsEventsHeaderLabel: UILabel!
    @IBOutlet weak var recentTransactionsEventsTableView: UITableView! {
        didSet {
            recentTransactionsEventsTableView.dataSource = self
            recentTransactionsEventsTableView.delegate = self
        }
    }
    
    
    
    
    // MARK: Properties
    
    var authListenerHandle: AuthStateDidChangeListenerHandle?
    var userID: String?
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.authListenerHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let currUser = user {
                // TODO: Download the user's info based on the userID.
                let userIDForLookup = self.userID ?? currUser.uid
                DataService.instance.getUser(withUID: userIDForLookup) { (user) in
                    guard let thisProfileUser = user else {
                        // TODO: Couldn't retrieve the user info for this screen.
                        return
                    }
                    
                    // Display the user's info.
                    self.nameLabel.text = "\(thisProfileUser.firstName) \(thisProfileUser.lastName)"
                    self.roleLabel.text = UserRole.stringFromInt(thisProfileUser.role) ?? "-"
                    self.emailLabel.text = thisProfileUser.emailAddress
                    self.balanceLabel.text = thisProfileUser.role == UserRole.student.toInt ? "Balance: \(thisProfileUser.pointBalance ?? 0) points" : "-"
                    
                    // Download and display the user's profile image.
                    Storage.storage().reference(forURL: thisProfileUser.imageURL).getData(maxSize: 2 * 1024 * 1024) { (data, error) in
                        if error != nil, data != nil {
                            self.imageView.image = UIImage(data: data!)
                        }
                    }
                    
                    
                    // Am I viewing my own profile or not?
                    if thisProfileUser.userID == currUser.uid {
                        // This is me! Add an edit button.
                        let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(self.handleEditTapped))
                        self.navigationItem.setRightBarButton(editButton, animated: true)
                    } else {
                        // This is someone else. Remove the sign out button.
                        self.signOutButton.isHidden = true
                        self.signOutButton.removeFromSuperview()
                        self.view.layoutIfNeeded()
                    }
                    
                    
                    // Configure UI based on the profile user's role.
                    switch thisProfileUser.role {
                    case UserRole.student.toInt:
                        self.recentTransactionsEventsHeaderLabel.text = "RECENT TRANSACTIONS:"
                        // TODO: Download recent transactions and populate the table view.
                        
                        // If I'm an admin looking at a student, I can initiate a manual transaction from here.
                        DataService.instance.getRoleForUser(withUID: currUser.uid) { (roleNum) in
                            if roleNum == UserRole.admin.toInt {
                                let manualTransactionButton = UIBarButtonItem(image: UIImage(named: "add-transaction"), style: .plain, target: self, action: #selector(self.handleManualTransactionButtonTapped))
                                self.navigationItem.setRightBarButton(manualTransactionButton, animated: true)
                            }
                        }
                    case UserRole.scheduler.toInt, UserRole.admin.toInt:
                        self.balanceLabel.removeFromSuperview()
                        self.view.layoutIfNeeded()
                        self.recentTransactionsEventsHeaderLabel.text = "UPCOMING/RECENT EVENTS:"
                        // TODO: Download recent events and populate the table view.
                    default:
                        // TODO: User role number is invalid.
                        break
                    }
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                }
                
                
                
                // TODO: If I'm an admin or scheduler AND this VC is the root "Profile" VC (AND this is my profile), show the "All Profiles" bar button item on the left.
                // TODO: If I'm an admin, I need the ability to add a manual transaction
            } else {
                // TODO: There is no user signed in!
            }
        }
        
        
        
    }
    
    
    
    
    // MARK: Table View methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    
    
    
    // MARK: Button Actions

    @IBAction func signOutTapped(_ sender: UIButton) {
        // TODO: Sign out and show the sign-in screen.
    }
    
    @objc private func handleEditTapped() {
        print("Brennan - edit tapped")
        // TODO: Navigate to the edit profile screen.
    }
    
    @objc private func handleAllProfilesTapped() {
        print("Brennan - all profiles tapped")
        // TODO: Navigate to the all profiles screen.
    }
    
    @objc private func handleManualTransactionButtonTapped() {
        print("Brennan - manual transaction tapped")
        // TODO: Navigate to the manual transaction screen, pre-populate the UI with this user's data, and make sure the user can only go back here from the next screen.
    }
    
    
    
    
    
    
    
    
    
    
    
    
    deinit {
        if self.authListenerHandle != nil { Auth.auth().removeStateDidChangeListener(self.authListenerHandle!) }
    }
    
    
}
