//
//  TransactionListVC.swift
//  Engauge
//
//  Created by Brennan Linse on 4/26/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class TransactionListVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    // MARK: Outlets
    
    @IBOutlet weak var searchBar: UISearchBar! { didSet { searchBar.delegate = self } }
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    
    
    
    
    // MARK: Properties
    
    // Storing transaction data
    private var transactions = [Transaction]()
    private var filteredTransactions: [Transaction]?
    
    // Searching
    private var searchOn: Bool { return searchText != nil }
    private var searchText: String? {
        didSet {
            if searchOn {
                applySearch()
            } else {
                filteredTransactions = nil
            }
            tableView.reloadData()
        }
    }
    
    // For observing database events
    private var schoolTransactionsRef: DatabaseReference?
    private var schoolTransactionsChildAddedHandle: DatabaseHandle?
    
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let currUser = Auth.auth().currentUser else {
            // TODO: There's nobody signed in!
            return
        }
        
        // Someone is signed in. Retrieve the transactions for his/her school.
        DataService.instance.getSchoolIDForUser(withUID: currUser.uid) { (currUserSchoolID) in
            if currUserSchoolID != nil {
                self.schoolTransactionsRef = DataService.instance.REF_SCHOOL_TRANSACTIONS.child(currUserSchoolID!)
                self.attachDatabaseObserver()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
    }
    
    
    
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toTransactionDetailsVC":
            if let transactionScreen = segue.destination as? TransactionDetailsVC, let pickedTransaction = sender as? Transaction {
                transactionScreen.transaction = pickedTransaction
            }
        default:
            break
        }
    }
    
    
    
    
    // MARK: Table View methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchOn ? (filteredTransactions?.count ?? 0) : transactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("TransactionTableViewCell", owner: self, options: nil)?.first as? TransactionTableViewCell
        let currTransaction = (searchOn ? filteredTransactions! : transactions)[indexPath.row]
        cell?.configureCell(transaction: currTransaction, forVCWithTypeName: "TransactionListVC")
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "toTransactionDetailsVC", sender: (searchOn ? self.filteredTransactions! : self.transactions)[indexPath.row])
    }
    
    
    
    
    // MARK: Search Bar methods
    
    // Clears out the existing search text when the user erases all of the text in the search bar.
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text == nil || searchText.isEmpty {
            self.searchText = nil
        }
    }
    
    // User tapped "Search." Sets the search text to whatever the user typed in the bar.
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        dismissKeyboard()
        guard let search = searchBar.text, !search.isEmpty else {
            // Searched without typing anything in the search bar.
            searchText = nil
            return
        }
        searchText = search
    }
    
    // User tapped "Cancel" on the search bar. Resets the search bar's text to reflect the current search.
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = searchText
        dismissKeyboard()
    }
    
    // Show the cancel button when the keyboard is visible.
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    // Hide the cancel button when the keyboard is not visible.
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    private func applySearch() {
        // Searching by TID
        if searchOn {
            self.filteredTransactions = self.transactions.filter { $0.transactionID.lowercased().contains(searchText!.lowercased()) }
        }
    }
    
    
    
    
    // MARK: Observing Database Events
    
    /** Assumes that self.schoolTransactionsRef is already set. */
    private func attachDatabaseObserver() {
        // A new transaction occurred
        self.schoolTransactionsChildAddedHandle = self.schoolTransactionsRef?.observe(.childAdded) { [weak self] (snapshot) in
            DataService.instance.getTransaction(withID: snapshot.key) { (addedTransaction) in
                if addedTransaction != nil {
                    self?.transactions.insert(addedTransaction!, at: 0)
                    self?.transactions.sort { $0.timestamp > $1.timestamp }
                    self?.applySearch()
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    
    
    
    // MARK: Removing Observers
    
    private func removeDatabaseObserversIfNecessary() {
        if self.schoolTransactionsChildAddedHandle != nil {
            schoolTransactionsRef?.removeObserver(withHandle: schoolTransactionsChildAddedHandle!)
        }
    }
    
    
    
    // MARK: Deinitializer
    
    deinit {
        print("Deallocating an instance of TransactionListVC")
        removeDatabaseObserversIfNecessary()
    }
}
