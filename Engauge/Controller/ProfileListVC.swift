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
    private var filteredUsers: [EngaugeUser]?
    
    private var searchOn: Bool { return searchText != nil }
    private var searchText: String? {
        didSet {
            if searchText == nil {
                // Just set searchText to nil.
                filteredUsers = nil
            } else {
                // Just set searchText to something.
                applySearch()
            }
            tableView.reloadData()
        }
    }
    
    static let imageCache = NSCache<NSString, UIImage>()
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DataService.instance.getSchoolIDForUser(withUID: Auth.auth().currentUser?.uid ?? "no-curr-user") { (currUserSchoolID) in
            guard currUserSchoolID != nil else {
                self.showErrorAlert(title: "Error", message: "Couldn't verify your school's ID.") { (okAction) in
                    self.dismiss(animated: true)
                }
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
        return searchOn ? (filteredUsers?.count ?? 0) : users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("ProfileTableViewCell", owner: self, options: nil)?.first as? ProfileTableViewCell
        let cacheImage = ProfileListVC.imageCache.object(forKey: (searchOn ? filteredUsers! : users)[indexPath.row].thumbnailURL as NSString)
        cell?.configureCell(user: users[indexPath.row], thumbnailImageFromCache: cacheImage, forVCWithTypeName: "ProfileListVC")
        return cell ?? UITableViewCell()
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
        if searchOn {
            self.filteredUsers = self.users.filter { $0.fullName.lowercased().contains(searchText!.lowercased()) }
        }
    }

    
    
    
    
    
    
    
    
}
