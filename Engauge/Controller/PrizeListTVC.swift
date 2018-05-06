//
//  PrizeListTVC.swift
//  Engauge
//
//  Created by Brennan Linse on 5/5/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class PrizeListTVC: UITableViewController {
    
    // MARK: Outlets
    
    
    
    
    // MARK: Properties
    
    private var prizes = [Prize]()
    
    
    // Database Observer Stuff
    private var allPrizesRef: DatabaseReference?
    private var schoolPrizesRef: DatabaseReference?
    
    private var prizeAddedHandle: DatabaseHandle?
    private var prizeRemovedHandle: DatabaseHandle?
    private var prizeDataChangedHandle: DatabaseHandle?
    
    static var imageCache: NSCache<NSString, UIImage> = NSCache<NSString, UIImage>()
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureAdaptableUI()
        attachDatabaseObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
    }
    
    
    
    
    // MARK: Updating the UI
    
    /** Adds or removes the "new event" button based on the current user's role. */
    private func configureAdaptableUI() {
        guard let currUserUID = Auth.auth().currentUser?.uid else {
            // TODO: Nobody is signed in!
            return
        }
        
        DataService.instance.getRoleForUser(withUID: currUserUID) { (roleNum) in
            guard let currUserRoleNum = roleNum else {
                // Couldn't retrieve the current user's role.
                self.navigationItem.setRightBarButtonItems(nil, animated: true)
                return
            }
            
            switch currUserRoleNum {
            case UserRole.admin.toInt:
                // Admins can add new prizes.
                let newPrizeButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.handleNewPrizeTapped))
                self.navigationItem.setRightBarButton(newPrizeButton, animated: true)
            
            default:
                // Other users can't add new prizes.
                self.navigationItem.setRightBarButtonItems(nil, animated: true)
            }
        }
    }
    
    
    
    
    // MARK: Database Observers
    
    /** Sets both allPrizesRef and schoolPrizesRef. */
    private func attachDatabaseObservers() {
        removeDatabaseObserversIfNecessary()
        self.prizes.removeAll()
        self.tableView.reloadData()
        
        guard let currUserUID = Auth.auth().currentUser?.uid else {
            return
        }
        
        DataService.instance.getSchoolIDForUser(withUID: currUserUID) { (schoolID) in
            guard let currUserSchoolID = schoolID else {
                return
            }
            
            self.schoolPrizesRef = DataService.instance.REF_SCHOOL_PRIZES.child(currUserSchoolID)
            self.allPrizesRef = DataService.instance.REF_PRIZES
            
            self.prizeAddedHandle = self.schoolPrizesRef?.observe(.childAdded) { (snapshot) in
                DataService.instance.getPrize(withID: snapshot.key) { (newPrize) in
                    if newPrize != nil {
                        self.prizes.append(newPrize!)
                        self.prizes.sort { $0.name < $1.name }
                        self.tableView.reloadData()
                    }
                }
            }
            
            self.prizeRemovedHandle = self.schoolPrizesRef?.observe(.childRemoved) { (snapshot) in
                if let indexOfPrizeToRemove = self.prizes.index(where: { $0.name == snapshot.key }) {
                    self.prizes.remove(at: indexOfPrizeToRemove)
                    self.tableView.reloadData()
                }
            }
            
            self.prizeDataChangedHandle = self.allPrizesRef?.observe(.childChanged) { (snapshot) in
                // Was the prize that changed in our array?
                if let indexOfChangedPrize = self.prizes.index(where: { $0.prizeID == snapshot.key }) {
                    // Can we build a prize object from the changed prize data?
                    if let changedPrizeData = snapshot.value as? [String : Any], let changedPrize = DataService.instance.prizeFromSnapshotValues(changedPrizeData, withID: snapshot.key) {
                        self.prizes[indexOfChangedPrize] = changedPrize
                    }
                    
                    self.tableView.reloadData()
                }
            }
            
        }
    }
    
    /**
     Ensures all observers are removed from their corresponding references.
     Discards existing observer handles.
     */
    private func removeDatabaseObserversIfNecessary() {
        if prizeAddedHandle != nil {
            schoolPrizesRef?.removeObserver(withHandle: prizeAddedHandle!)
            prizeAddedHandle = nil
        }
        if prizeRemovedHandle != nil {
            schoolPrizesRef?.removeObserver(withHandle: prizeRemovedHandle!)
            prizeRemovedHandle = nil
        }
        if prizeDataChangedHandle != nil {
            allPrizesRef?.removeObserver(withHandle: prizeDataChangedHandle!)
            prizeDataChangedHandle = nil
        }
    }
    
    
    
    
    // MARK: Button Actions
    
    @objc private func handleNewPrizeTapped() {
        performSegue(withIdentifier: "toNewPrizeTVC", sender: nil)
    }
    
    
    
    
    // MARK: Table View Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return prizes.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("PrizeTableViewCell", owner: self, options: nil)?.first as? PrizeTableViewCell
        cell?.configureCellForVC(withTypeName: "PrizeListTVC", prize: prizes[indexPath.row])
        return cell ?? UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "toPrizeDetailsVC", sender: prizes[indexPath.row].prizeID)
    }
    
    
    
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case "toPrizeDetailsVC":
            if let prizeScreen = segue.destination as? PrizeDetailsVC, let pickedPrizeID = sender as? String {
                prizeScreen.prizeID = pickedPrizeID
            }
            
        case "toNewPrizeTVC":
            break
            
        default:
            break
        }
    }
    
    
    
    
    // MARK: Deinitializer
    
    deinit {
        removeDatabaseObserversIfNecessary()
    }
    
}
