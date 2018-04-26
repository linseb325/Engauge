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
import FirebaseDatabase

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
    
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    
    // userID is only for fetching initial data when this screen loads.
    var userID: String?
    private var thisProfileUser: EngaugeUser?
    
    // Database references to attach event observers
    private var userEventsRef: DatabaseReference?
    private var userTransactionsRef: DatabaseReference?
    
    var adminIsChoosingForManualTransaction = false
    
    private var usersScheduledEvents: [Event]?
    private var usersRecentTransactions: [Transaction]?
    
    private var tableViewMode = TableViewMode.none
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.authListenerHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            guard let currUser = user else {
                // TODO: There is no user signed in!
                return
            }
            
            // There is a user signed in.
            let userIDForLookup = self.userID ?? currUser.uid
            
            DataService.instance.getUser(withUID: userIDForLookup) { (user) in
                guard let thisProfileUser = user else {
                    // TODO: Couldn't retrieve the user info for this screen.
                    return
                }
                
                self.thisProfileUser = thisProfileUser
                
                self.updateUIForCurrentUser()
                self.configureAdaptableUI(currUser: currUser, thisProfileUser: thisProfileUser)
            }
        }
        
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let selectedIndexPath = recentTransactionsEventsTableView.indexPathForSelectedRow {
            recentTransactionsEventsTableView.deselectRow(at: selectedIndexPath, animated: true)
        }
    }
    
    
    
    
    // MARK: Updating the UI
    
    private func updateUIForCurrentUser() {
        
        // Check to make sure thisProfileUser is assigned to something.
        guard let thisProfileUser = self.thisProfileUser else {
            return
        }
        
        // Download and display the user's profile image.
        Storage.storage().reference(forURL: thisProfileUser.thumbnailURL).getData(maxSize: 2 * 1024 * 1024) { (data, error) in
            if error == nil, data != nil {
                self.imageView.image = UIImage(data: data!)
            }
        }
        
        // Display the user's info.
        self.nameLabel.text = "\(thisProfileUser.firstName) \(thisProfileUser.lastName)"
        self.roleLabel.text = UserRole.stringFromInt(thisProfileUser.role)?.capitalized ?? "-"
        self.emailLabel.text = thisProfileUser.emailAddress
        self.balanceLabel.text = (thisProfileUser.role == UserRole.student.toInt) ? "Balance: \(thisProfileUser.pointBalance ?? 0) points" : "-"
        
    }
    
    // Configures UI based on the roles of the current user and the user he/she is viewing.
    // This affects: Edit button, All Users button, Sign Out button, Table View Header + Content, self.tableViewMode, Balance label
    private func configureAdaptableUI(currUser: User, thisProfileUser: EngaugeUser) {
        
        // Am I looking at my own profile?
        if thisProfileUser.userID == currUser.uid {
            // This is me!
            if self.isFirstVisibleVCofATab {
                // I can edit my profile from this screen.
                let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(self.handleEditTapped))
                self.navigationItem.setRightBarButton(editButton, animated: true)
                
                // If I'm an Admin or Scheduler, I can get to the list of profiles from here.
                DataService.instance.getRoleForUser(withUID: currUser.uid) { (roleNum) in
                    if let currUserRoleNum = roleNum, (currUserRoleNum == UserRole.admin.toInt || currUserRoleNum == UserRole.scheduler.toInt) {
                        // User can navigate to the profile list from here.
                        let allProfilesButton = UIBarButtonItem(title: "All Users", style: .plain, target: self, action: #selector(self.handleAllUsersTapped))
                        self.navigationItem.setLeftBarButton(allProfilesButton, animated: true)
                    }
                }
            }
        } else {
            // This is someone else. Hide the sign out button.
            self.signOutButton.isHidden = true
            self.view.layoutIfNeeded()
        }
        
        // What kind of user am I looking at?
        switch thisProfileUser.role {
        case UserRole.student.toInt:
            // I'm looking at a student
            // Download recent transactions and populate the table view.
            self.tableViewMode = .transactions
            self.recentTransactionsEventsHeaderLabel.text = "RECENT TRANSACTIONS:"
            self.userTransactionsRef = DataService.instance.REF_USER_TRANSACTIONS.child(thisProfileUser.userID)
            self.usersRecentTransactions = []
            self.usersScheduledEvents = nil
            self.attachDatabaseObservers(forTableViewMode: .transactions)
            // If I'm an admin looking at a student, I can initiate a manual transaction from here.
            DataService.instance.getRoleForUser(withUID: currUser.uid) { (currUserRoleNum) in
                if currUserRoleNum == UserRole.admin.toInt {
                    if self.adminIsChoosingForManualTransaction {
                        // Admin can choose this user for a pending manual transaction.
                        let chooseForManualTransactionButton = UIBarButtonItem(title: "Choose", style: .done, target: self, action: #selector(self.handleChooseForManualTransactionButtonTapped))
                        self.navigationItem.setRightBarButton(chooseForManualTransactionButton, animated: true)
                    } else {
                        // Admin can initiate a manual transaction with this user.
                        let manualTransactionButton = UIBarButtonItem(image: UIImage(named: "add-transaction"), style: .plain, target: self, action: #selector(self.handleManualTransactionButtonTapped))
                        self.navigationItem.setRightBarButton(manualTransactionButton, animated: true)
                    }
                }
            }
        case UserRole.scheduler.toInt, UserRole.admin.toInt:
            // I'm looking at a scheduler or admin
            self.balanceLabel.isHidden = true
            self.view.layoutIfNeeded()
            // Download recent events and populate the table view.
            self.tableViewMode = .events
            self.recentTransactionsEventsHeaderLabel.text = "UPCOMING/RECENT EVENTS:"
            self.userEventsRef = DataService.instance.REF_USER_EVENTS.child(thisProfileUser.userID)
            self.usersScheduledEvents = []
            self.usersRecentTransactions = nil
            self.attachDatabaseObservers(forTableViewMode: .events)
        default:
            // TODO: User role number is invalid.
            break
        }

    }
    
    
    
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toProfileListVC":
            break
        case "toEditProfileVC":
            if let editScreen = segue.destination.contentsViewController as? EditProfileVC, let currUser = sender as? EngaugeUser {
                editScreen.user = currUser
            }
        case "toEventDetailsVC":
            if let eventScreen = segue.destination.contentsViewController as? EventDetailsVC, let pickedEvent = sender as? Event {
                eventScreen.event = pickedEvent
            }
        case "toTransactionDetailsVC":
            // TODO: Set the next screen's transaction to pickedTransaction.
            break
        default:
            break
        }
    }
    
    @IBAction func unwindFromEditProfileVC(sender: UIStoryboardSegue) {
        if let sourceVC = sender.source as? EditProfileVC, let editedUser = sourceVC.editedUser {
            self.thisProfileUser = editedUser
            updateUIForCurrentUser()
        }
    }

    
    
    
    
    // MARK: Table View methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.tableViewMode {
        case .events:
            return self.usersScheduledEvents?.count ?? 0
        case .transactions:
            return self.usersRecentTransactions?.count ?? 0
        case .none:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.tableViewMode {
        case .events:
            let cell = Bundle.main.loadNibNamed("EventTableViewCell", owner: self, options: nil)?.first as? EventTableViewCell
            cell?.configureCell(event: self.usersScheduledEvents![indexPath.row], forVCWithTypeName: "ProfileDetailsVC")
            return cell ?? UITableViewCell()
        case .transactions:
            let cell = Bundle.main.loadNibNamed("TransactionTableViewCell", owner: self, options: nil)?.first as? TransactionTableViewCell
            cell?.configureCell(transaction: self.usersRecentTransactions![indexPath.row], forVCWithTypeName: "ProfileDetailsVC")
            return cell ?? UITableViewCell()
        case .none:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch self.tableViewMode {
        case .events:
            return 80
        case .transactions:
            return 44
        case .none:
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.tableViewMode {
        case .events:
            performSegue(withIdentifier: "toEventDetailsVC", sender: self.usersScheduledEvents![indexPath.row])
        case .transactions:
            // TODO: Navigate to the Transaction Details screen. Pass the picked transaction to performSegue as the sender.
            break
        case .none:
            break
        }
    }
    
    
    
    // MARK: Table View Mode
    
    private enum TableViewMode {
        case transactions
        case events
        case none
    }
    
    
    
    
    // MARK: Button Actions

    @IBAction func signOutTapped(_ sender: UIButton) {
        print("Brennan - sign out tapped")
        // TODO: Sign out and show the sign-in screen.
    }
    
    @objc private func handleEditTapped() {
        guard let thisProfileUser = self.thisProfileUser else {
            return
        }
        performSegue(withIdentifier: "toEditProfileVC", sender: thisProfileUser)
    }
    
    @objc private func handleAllUsersTapped() {
        performSegue(withIdentifier: "toProfileListVC", sender: nil)
    }
    
    @objc private func handleManualTransactionButtonTapped() {
        print("Brennan - manual transaction tapped")
        // TODO: Navigate to the manual transaction screen, pre-populate the UI with this user's data, and make sure the user can only go back here from the next screen.
    }
    
    @objc private func handleChooseForManualTransactionButtonTapped() {
        // TODO: Unwind to the manual transaction details screen, passing the selected user back to that screen.
    }
    
    
    
    
    private func attachDatabaseObservers(forTableViewMode mode: TableViewMode) {
        guard (userEventsRef != nil || userTransactionsRef != nil) else {
            print("Brennan - Database refs weren't set before trying to attach observers")
            return
        }
        
        
        switch mode {
            
        case .events:
            // This user scheduled an event
            self.userEventsRef?.observe(.childAdded, with: { (snapshot) in
                print("Event added")
                DataService.instance.getEvent(withID: snapshot.key, completion: { (addedEvent) in
                    if addedEvent != nil {
                        self.usersScheduledEvents?.append(addedEvent!)
                        self.usersScheduledEvents?.sort { $0.startTime > $1.startTime }
                        self.recentTransactionsEventsTableView.reloadData()
                    }
                })
            })
            // This user removed an event
            self.userEventsRef?.observe(.childRemoved, with: { (snapshot) in
                print("Event removed")
                self.usersScheduledEvents?.removeEvent(withID: snapshot.key)
                self.recentTransactionsEventsTableView.reloadData()
            })
            
        case .transactions:
            // This user was involved in a transaction
            self.userTransactionsRef?.observe(.childAdded, with: { (snapshot) in
                print("Transaction added")
                DataService.instance.getTransaction(withID: snapshot.key) { (addedTransaction) in
                    if addedTransaction != nil {
                        self.usersRecentTransactions?.append(addedTransaction!)
                        self.usersRecentTransactions?.sort { $0.timestamp > $1.timestamp }
                        self.recentTransactionsEventsTableView.reloadData()
                    }
                }
            })
            // A transaction was removed for this user
            self.userTransactionsRef?.observe(.childRemoved, with: { (snapshot) in
                print("Transaction removed")
                self.usersRecentTransactions?.removeTransaction(withID: snapshot.key)
                self.recentTransactionsEventsTableView.reloadData()
            })
            
        default:
            print("Brennan - Table view mode is neither .events nor .transactions. Couldn't attach observers.")
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    deinit {
        if self.authListenerHandle != nil { Auth.auth().removeStateDidChangeListener(self.authListenerHandle!) }
        
        self.userEventsRef?.removeAllObservers()
        self.userTransactionsRef?.removeAllObservers()
    }
    
    
}
