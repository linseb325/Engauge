//
//  ProfileListVC.swift
//  Engauge
//
//  Created by Brennan Linse on 4/21/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import FirebaseAuth

class ProfileListVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    // MARK: Outlets
    
    @IBOutlet weak var searchBar: UISearchBar! { didSet { searchBar.delegate = self } }
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    
    
    
    
    
    // MARK: Properties
    
    private var users = [EngaugeUser]()
    
    private var searchText: String? {
        didSet {
            // TODO
        }
    }
    
    static let imageCache = NSCache<NSString, UIImage>()
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DataService.instance.getSchoolIDForUser(withUID: Auth.auth().currentUser?.uid ?? "no-curr-user") { (currUserSchoolID) in
            guard currUserSchoolID != nil else {
                self.dismiss(animated: true)
                return
            }
            
            DataService.instance.getUsersForSchool(withID: currUserSchoolID!) { (retrievedUsers) in
                self.users = retrievedUsers
                self.users.sort { $0.lastName < $1.lastName }
                self.tableView.reloadData()
            }
            
        }
        
        
        
        
    }
    
    
    
    
    // MARK: Table View methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("", owner: self, options: nil)?.first as? ProfileTableViewCell
        cell?.configureCell(user: users[indexPath.row], thumbnailImageFromCache: ProfileListVC.imageCache.object(forKey: users[indexPath.row].thumbnailURL as NSString), forVCWithTypeName: "ProfileListVC")
        return cell ?? UITableViewCell()
    }
    
    
    
    
    // MARK: Search Bar methods
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        <#code#>
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        <#code#>
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        <#code#>
    }

    
    
    
    
    
    
    
    
}
