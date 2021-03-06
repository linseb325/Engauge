//
//  ProfileDetailsVC.swift
//  Engauge
//
//  Created by Brennan Linse on 4/16/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//
//  PURPOSE: View a user's info and/or sign out.

import UIKit
import FirebaseAuth
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
    
    // userID is only for fetching initial data when this screen loads.
    var userID: String?
    private var currUserID: String?
    var thisProfileUser: EngaugeUser?
    
    // Database references and handles for event observers
    private var userEventsRef: DatabaseReference?
    private var userTransactionsRef: DatabaseReference?
    private var userInfoRef: DatabaseReference?
    
    private var eventAddedHandle: DatabaseHandle?
    private var eventRemovedHandle: DatabaseHandle?
    
    private var transactionAddedHandle: DatabaseHandle?
    private var transactionRemovedHandle: DatabaseHandle?
    
    private var userInfoChangedHandle: DatabaseHandle?
    
    // Event and Transaction data
    var adminIsChoosingForManualTransaction = false
    
    private var usersScheduledEvents: [Event]?
    private var usersRecentTransactions: [Transaction]?
    
    private var tableViewMode = TableViewMode.none
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if adminIsChoosingForManualTransaction {
            disableTableViewSelection()
        } else {
            enableTableViewSelection()
        }
        
        guard let currUser = Auth.auth().currentUser else {
            self.currUserID = nil
            // TODO: Nobody is signed in!
            return
        }
        
        // There is a user signed in.
        self.currUserID = currUser.uid
        if self.userID == nil {
            self.userID = currUser.uid
        }
        
        self.userInfoRef = DataService.instance.REF_USERS.child(self.userID!)
        self.attachUserInfoDatabaseObserver()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let selectedIndexPath = recentTransactionsEventsTableView.indexPathForSelectedRow {
            recentTransactionsEventsTableView.deselectRow(at: selectedIndexPath, animated: true)
        }
    }
    
    
    
    
    // MARK: Updating the UI
    
    // Sets the user's profile image and labels.
    // Requires that self.thisProfileUser is already set.
    private func updateUIForCurrentUser() {
        
        guard let thisProfileUser = self.thisProfileUser else {
            return
        }
        
        // Download and display the user's profile image.
        StorageService.instance.getImageForUser(withUID: thisProfileUser.userID, thumbnail: true) { (profileImage) in
            self.imageView.image = profileImage
        }
        
        // Display the user's info.
        self.nameLabel.text = "\(thisProfileUser.firstName) \(thisProfileUser.lastName)"
        self.roleLabel.text = UserRole.stringFromInt(thisProfileUser.role)?.capitalized ?? "-"
        self.emailLabel.text = thisProfileUser.emailAddress
        self.balanceLabel.text = (thisProfileUser.role == UserRole.student.toInt) ? "Balance: \(thisProfileUser.pointBalance ?? 0) point(s)" : "-"
        
    }
    
    
    // Configures UI based on the roles of the current user and the user he/she is viewing.
    // Asks two questions:
        // (1) Am I looking at my own profile, and is this VC the first in the "Profile" tab? [Edit, All Users, Sign Out]
        // (2) What is this user's role?
    // This affects: Edit button, All Users button, Sign Out button, Table View Header + Content, self.tableViewMode, Balance label
    private func configureAdaptableUI() {
        
        guard let thisProfileUser = self.thisProfileUser else {
            return
        }
        
        guard let currUserID = self.currUserID else {
            return
        }
        
        DataService.instance.getRoleForUser(withUID: currUserID) { (roleNum) in
            
            guard let currUserRoleNum = roleNum else {
                return
            }
            
            // Am I looking at my own profile?
            if thisProfileUser.userID == currUserID {
                // This is me!
                // Is this the root of the "Profile" tab?
                if self.isFirstVisibleVCofATab {
                    // I can edit my profile from here.
                    let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(self.handleEditTapped))
                    self.navigationItem.setRightBarButton(editButton, animated: true)
                    // I can sign out from here.
                    self.signOutButton.isHidden = false
                    
                    // If I'm an Admin or Scheduler, I can get to the list of profiles from here.
                    if currUserRoleNum == UserRole.admin.toInt || currUserRoleNum == UserRole.scheduler.toInt {
                        // User can navigate to the profile list from here.
                        let allProfilesButton = UIBarButtonItem(title: "All Users", style: .plain, target: self, action: #selector(self.handleAllUsersTapped))
                        self.navigationItem.setLeftBarButton(allProfilesButton, animated: true)
                    } else {
                        // User can't navigate to the profile list from here.
                        self.navigationItem.setLeftBarButton(nil, animated: true)
                    }
                }
            } else {
                // This is someone else. Hide the sign out button and remove the edit button if it's present.
                self.navigationItem.setRightBarButton(nil, animated: true)
                self.signOutButton.isHidden = true
                self.view.layoutIfNeeded()
            }
            
            // What kind of user am I looking at?
            switch thisProfileUser.role {
                
            case UserRole.student.toInt:
                // I'm looking at a student
                self.balanceLabel.isHidden = false
                self.view.layoutIfNeeded()
                // Download recent transactions and populate the table view.
                self.recentTransactionsEventsHeaderLabel.text = "RECENT TRANSACTIONS:"
                self.userTransactionsRef = DataService.instance.REF_USER_TRANSACTIONS.child(thisProfileUser.userID)
                self.usersRecentTransactions = [Transaction]()
                self.usersScheduledEvents = nil
                self.tableViewMode = .transactions
                self.recentTransactionsEventsTableView.reloadData()     // Gotta include this to refresh the table view if there's no transactions for this user.
                self.attachTableViewDatabaseObservers()
                
                // If I'm an admin looking at a student, I can initiate a manual transaction from here.
                if currUserRoleNum == UserRole.admin.toInt {
                    if self.adminIsChoosingForManualTransaction {
                        // Admin can choose this user for a pending manual transaction.
                        let chooseForManualTransactionButton = UIBarButtonItem(title: "Choose", style: .done, target: self, action: #selector(self.handleChooseForManualTransactionButtonTapped))
                        self.navigationItem.setRightBarButton(chooseForManualTransactionButton, animated: true)
                        self.disableTableViewSelection()
                    } else {
                        // Admin can initiate a manual transaction with this user.
                        let manualTransactionButton = UIBarButtonItem(image: UIImage(named: "swap"), style: .plain, target: self, action: #selector(self.handleInitiateManualTransactionButtonTapped))
                        self.navigationItem.setRightBarButton(manualTransactionButton, animated: true)
                    }
                }
                
            case UserRole.scheduler.toInt, UserRole.admin.toInt:
                // I'm looking at a scheduler or admin
                self.balanceLabel.isHidden = true
                self.view.layoutIfNeeded()
                // Download recent events and populate the table view.
                self.recentTransactionsEventsHeaderLabel.text = "UPCOMING/RECENT EVENTS:"
                self.userEventsRef = DataService.instance.REF_USER_EVENTS.child(thisProfileUser.userID)
                self.usersScheduledEvents = [Event]()
                self.usersRecentTransactions = nil
                self.tableViewMode = .events
                self.recentTransactionsEventsTableView.reloadData()     // Gotta include this to refresh the table view if there's no events for this user.
                self.attachTableViewDatabaseObservers()
                
            default:
                // User role number is invalid. Should never happen.
                break
            }
        }
        
    }
    
    private func hideTableViewUI() {
        self.recentTransactionsEventsTableView.isHidden = true
        self.recentTransactionsEventsHeaderLabel.isHidden = true
    }
    
    private func showTableViewUI() {
        self.recentTransactionsEventsTableView.isHidden = false
        self.recentTransactionsEventsHeaderLabel.isHidden = false
    }
    
    
    
    
    // MARK: Database Observers
    
    // Requires that userInfoRef is already set.
    // This observer will update the viewed user's UI and the adaptable UI whenever user data changes.
    // Calls both updateUIForCurrentUser() and configureAdaptableUI() immediately when the observer is attached.
    private func attachUserInfoDatabaseObserver() {
        removeUserInfoDatabaseObserverIfNecessary()
        
        self.userInfoChangedHandle = userInfoRef?.observe(.value) { [weak self] (snapshot) in
            if let userData = snapshot.value as? [String : Any], let updatedUser = DataService.instance.userFromSnapshotValues(userData, withUID: snapshot.key) {
                self?.thisProfileUser = updatedUser
                self?.updateUIForCurrentUser()
                self?.configureAdaptableUI()
            }
        }
    }
    
    // Requires that the table view database refs are already set.
    // Detaches any existing observers at the references.
    private func attachTableViewDatabaseObservers() {
        guard (userEventsRef != nil || userTransactionsRef != nil) else {
            print("BRENNAN - Database refs weren't set before trying to attach observers")
            return
        }
        
        switch self.tableViewMode {
            
        case .events:
            removeTableViewDatabaseObserversIfNecessary()
            
            // This user scheduled an event
            self.eventAddedHandle = self.userEventsRef?.observe(.childAdded) { [weak self] (snapshot) in
                DataService.instance.getEvent(withID: snapshot.key) { (addedEvent) in
                    if addedEvent != nil {
                        self?.usersScheduledEvents?.append(addedEvent!)
                        self?.usersScheduledEvents?.sort { $0.startTime > $1.startTime }
                        self?.recentTransactionsEventsTableView.reloadData()
                    }
                }
            }
            // This user removed an event
            self.eventRemovedHandle = self.userEventsRef?.observe(.childRemoved) { [weak self] (snapshot) in
                self?.usersScheduledEvents?.removeEvent(withID: snapshot.key)
                self?.recentTransactionsEventsTableView.reloadData()
            }
            
        case .transactions:
            removeTableViewDatabaseObserversIfNecessary()
            
            // This user was involved in a transaction
            self.transactionAddedHandle = self.userTransactionsRef?.observe(.childAdded) { [weak self] (snapshot) in
                DataService.instance.getTransaction(withID: snapshot.key) { (addedTransaction) in
                    if addedTransaction != nil {
                        self?.usersRecentTransactions?.append(addedTransaction!)
                        self?.usersRecentTransactions?.sort { $0.timestamp > $1.timestamp }
                        self?.recentTransactionsEventsTableView.reloadData()
                    }
                }
            }
            // A transaction was removed for this user (probably impossible)
            self.transactionRemovedHandle = self.userTransactionsRef?.observe(.childRemoved) { [weak self] (snapshot) in
                self?.usersRecentTransactions?.removeTransaction(withID: snapshot.key)
                self?.recentTransactionsEventsTableView.reloadData()
            }
            
        default:
            print("BRENNAN - Table view mode is neither .events nor .transactions. Couldn't attach observers.")
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
            if let transactionScreen = segue.destination.contentsViewController as? TransactionDetailsVC, let pickedTransaction = sender as? Transaction {
                transactionScreen.transaction = pickedTransaction
            }
        case "toManualTransactionVC":
            if let manualTransactionScreen = segue.destination.contentsViewController as? ManualTransactionVC, let thisProfileUser = self.thisProfileUser {
                manualTransactionScreen.canChangeSelectedUser = false
                manualTransactionScreen.selectedUser = thisProfileUser
            }
        case "unwindToManualTransactionVC":
            break
        default:
            break
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // "unwindToManualTransactionVC" is the only segue allowed if choosing for a manual transaction.
        if adminIsChoosingForManualTransaction, identifier != "unwindToManualTransactionVC" {
            return false
        }
        return true
    }
    
    
    
    
    // MARK: Table View methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
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
        case .transactions, .none:
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.tableViewMode {
        case .events:
            performSegue(withIdentifier: "toEventDetailsVC", sender: self.usersScheduledEvents![indexPath.row])
        case .transactions:
            performSegue(withIdentifier: "toTransactionDetailsVC", sender: self.usersRecentTransactions![indexPath.row])
        case .none:
            break
        }
    }
    
    private func disableTableViewSelection() {
        recentTransactionsEventsTableView.allowsSelection = false
    }
    
    private func enableTableViewSelection() {
        recentTransactionsEventsTableView.allowsSelection = true
    }
    
    
    
    
    // MARK: Table View Mode
    
    private enum TableViewMode {
        case transactions
        case events
        case none
    }
    
    
    
    
    // MARK: Button Actions

    @IBAction func signOutTapped(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
        } catch let signOutError {
            print("Brennan - there was an error trying to sign out in ProfileDetailsVC: \(signOutError.localizedDescription)")
        }
    }
    
    @objc private func handleEditTapped() {
        if let thisProfileUser = self.thisProfileUser {
            performSegue(withIdentifier: "toEditProfileVC", sender: thisProfileUser)
        }
    }
    
    @objc private func handleAllUsersTapped() {
        performSegue(withIdentifier: "toProfileListVC", sender: nil)
    }
    
    @objc private func handleInitiateManualTransactionButtonTapped() {
        // Navigate to the manual transaction screen, pre-populate the UI with this user's data, and make sure the user can only go back here from the next screen.
        if let thisProfileUser = self.thisProfileUser {
            performSegue(withIdentifier: "toManualTransactionVC", sender: thisProfileUser)
        }
    }
    
    @objc private func handleChooseForManualTransactionButtonTapped() {
        // Unwind to the manual transaction details screen, passing the selected user back to that screen.
        guard let thisUsersRole = thisProfileUser?.role, thisUsersRole == UserRole.student.toInt else {
            showErrorAlert(message: "This user isn't a student, so you can't choose him/her for a manual transaction.")
            return
        }
        
        performSegue(withIdentifier: "unwindToManualTransactionVC", sender: nil)
    }
    
    
    
    
    // MARK: Removing Observers
    
    private func removeTableViewDatabaseObserversIfNecessary() {
        if eventAddedHandle != nil   {
            userEventsRef?.removeObserver(withHandle: eventAddedHandle!)
            eventAddedHandle = nil
        }
        if eventRemovedHandle != nil {
            userEventsRef?.removeObserver(withHandle: eventRemovedHandle!)
            eventRemovedHandle = nil
        }
        if transactionAddedHandle != nil   {
            userTransactionsRef?.removeObserver(withHandle: transactionAddedHandle!)
            transactionAddedHandle = nil
        }
        if transactionRemovedHandle != nil {
            userTransactionsRef?.removeObserver(withHandle: transactionRemovedHandle!)
            transactionRemovedHandle = nil
        }
    }
    
    private func removeUserInfoDatabaseObserverIfNecessary() {
        if userInfoChangedHandle != nil {
            userInfoRef?.removeObserver(withHandle: userInfoChangedHandle!)
            userInfoChangedHandle = nil
        }
    }
    
    
    
    
    // MARK: Deinitializer
    
    deinit {
        print("Deallocating an instance of ProfileDetailsVC")
        removeUserInfoDatabaseObserverIfNecessary()
        removeTableViewDatabaseObserversIfNecessary()
    }
    
}
