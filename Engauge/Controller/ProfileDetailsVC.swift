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
    var thisProfileUser: EngaugeUser?
    
    var usersScheduledEvents: [Event]?
    var usersRecentTransactions: [Transaction]?
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.authListenerHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let currUser = user {
                // There is a user signed in.
                
                let userIDForLookup = self.userID ?? currUser.uid
                
                DataService.instance.getUser(withUID: userIDForLookup) { (user) in
                    guard let thisProfileUser = user else {
                        // TODO: Couldn't retrieve the user info for this screen.
                        return
                    }
                    
                    self.thisProfileUser = thisProfileUser
                    
                    // Is the current user authorized to view all profiles from this screen?
                    if self.isFirstVisibleVCofATab, userIDForLookup == currUser.uid {
                        DataService.instance.getRoleForUser(withUID: currUser.uid) { (roleNum) in
                            if let currUserRoleNum = roleNum, (currUserRoleNum == UserRole.admin.toInt || currUserRoleNum == UserRole.scheduler.toInt) {
                                // User can navigate to the profile list from here.
                                let allProfilesButton = UIBarButtonItem(title: "All Profiles", style: .plain, target: self, action: #selector(self.handleAllProfilesTapped))
                                self.navigationItem.setLeftBarButton(allProfilesButton, animated: true)
                            }
                        }
                    }
                    
                    // Display the user's info.
                    self.nameLabel.text = "\(thisProfileUser.firstName) \(thisProfileUser.lastName)"
                    self.roleLabel.text = UserRole.stringFromInt(thisProfileUser.role)?.capitalized ?? "-"
                    self.emailLabel.text = thisProfileUser.emailAddress
                    self.balanceLabel.text = thisProfileUser.role == UserRole.student.toInt ? "Balance: \(thisProfileUser.pointBalance ?? 0) points" : "-"
                    
                    // Download and display the user's profile image.
                    Storage.storage().reference(forURL: thisProfileUser.thumbnailURL).getData(maxSize: 2 * 1024 * 1024) { (data, error) in
                        if error == nil, data != nil {
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
                    
                    
                    // What kind of user am I looking at? (role)
                    switch thisProfileUser.role {
                    case UserRole.student.toInt:
                        // I'm looking at a student
                        self.recentTransactionsEventsHeaderLabel.text = "RECENT TRANSACTIONS:"
                        // TODO: Download recent transactions and populate the table view.
                        DataService.instance.getTransactionsForUser(withUID: thisProfileUser.userID) { (studentsTransactions) in
                            self.usersRecentTransactions = studentsTransactions
                            self.usersRecentTransactions?.sort { $0.timestamp > $1.timestamp }
                            self.recentTransactionsEventsTableView.reloadData()
                        }
                        // If I'm an admin looking at a student, I can initiate a manual transaction from here.
                        DataService.instance.getRoleForUser(withUID: currUser.uid) { (roleNum) in
                            if roleNum == UserRole.admin.toInt {
                                let manualTransactionButton = UIBarButtonItem(image: UIImage(named: "add-transaction"), style: .plain, target: self, action: #selector(self.handleManualTransactionButtonTapped))
                                self.navigationItem.setRightBarButton(manualTransactionButton, animated: true)
                            }
                        }
                    case UserRole.scheduler.toInt, UserRole.admin.toInt:
                        // I'm looking at a scheduler or admin
                        self.balanceLabel.removeFromSuperview()
                        self.view.layoutIfNeeded()
                        // Download recent events and populate the table view.
                        self.recentTransactionsEventsHeaderLabel.text = "UPCOMING/RECENT EVENTS:"
                        DataService.instance.getEventsScheduledByUser(withUID: thisProfileUser.userID) { (schedulersEvents) in
                            self.usersScheduledEvents = schedulersEvents
                            self.usersScheduledEvents?.sort { $0.startTime > $1.startTime }
                            self.recentTransactionsEventsTableView.reloadData()
                        }
                    default:
                        // TODO: User role number is invalid.
                        break
                    }
                    
                }
            } else {
                // TODO: There is no user signed in!
                print("Nobody is signed in")
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
        print("Brennan - sign out tapped")
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
