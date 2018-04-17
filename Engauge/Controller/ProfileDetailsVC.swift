//
//  ProfileDetailsVC.swift
//  Engauge
//
//  Created by Brennan Linse on 4/16/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit

class ProfileDetailsVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Outlets
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    
    @IBOutlet weak var recentTransactionsEventsHeaderLabel: UILabel!
    @IBOutlet weak var recentTransactionsEventsTableView: UITableView! {
        didSet {
            recentTransactionsEventsTableView.dataSource = self
            recentTransactionsEventsTableView.delegate = self
        }
    }
    
    
    
    
    // MARK: Properties
    
    var userID: String!
    
    
    
    
    
    
    
    
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: Download the user's info based on the userID.
        // TODO: Download the user's profile image.
        // TODO: Add an Edit button if this is my profile.
        // TODO: Remove the sign out button if this is not my profile.
        // TODO: If this is a student, download recent transactions and populate the table view.
        // TODO: If this is a scheduler or admin, download recent events and populate the table view.
        // TODO: If I'm an admin or scheduler AND this VC is the root "Profile" VC, show the "All Profiles" bar button item on the left.
        
        
        
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
    
    
    
    
    
}
