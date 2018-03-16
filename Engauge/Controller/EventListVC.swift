//
//  EventListVC.swift
//  Engauge
//
//  Created by Brennan Linse on 3/12/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import FirebaseAuth

class EventListVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    // MARK: Outlets
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    @IBOutlet weak var searchBar: UISearchBar! { didSet { searchBar.delegate = self } }
    
    
    
    // MARK: Properties
    
    // Event data
    // private var events: [[Event]] = [[Event](), [Event]()]
    private var events = [Event]()
    private var filteredEvents: [Event]?
    
    // Searching
    private var searchOn: Bool { return searchText != nil }
    private var searchText: String? {
        didSet {
            print("Brennan - did set searchText")
            if searchOn {
                // Just set searchText to something.
                // Re-apply filters, then apply searchText.
                applyFilters()
                applySearch()
            } else {
                // Just set the searchText to nil.
                // There might still be filters, though.
                if filtersOn {
                    applyFilters()
                } else {
                    self.filteredEvents = nil
                }
            }
            tableView.reloadData()
        }
    }
    // Filtering
    private var filtersOn: Bool { return filters != nil }
    var filters: [EventFilterFactory.EventFilter]? {
        didSet {
            print("Brennan - did set filters")
            searchBar.text = nil    // Gotta clear the search text in UI.
            searchText = nil        // Gotta clear the search text.
            if filtersOn {
                applyFilters()
            } else {
                // Just set the filters to nil.
                // Search text must also be nil, so there are no filtered events.
                self.filteredEvents = nil
            }
            tableView.reloadData()
        }
    }
    
    // For profile image thumbnails
    static var imageCache = NSCache<NSString, UIImage>()
    
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Checking to see if a user is signed in
        // EXECUTES ANY TIME THE AUTH STATE CHANGES
        self.authListenerHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            print("Brennan - Auth listener in EventListVC fired")
            if let currUser = user {
                // User is logged in, so retrieve events.
                print("Brennan - EventListVC auth listener in viewDidLoad says current user's e-mail is: \(currUser.email ?? "nil")")
                self.events = TEST_EVENTS
                DataService.instance.getSchoolIDForUserWithUID(currUser.uid) { (schoolID) in
                    if let userSchoolID = schoolID {
                        // Got the user's school ID.
                        DataService.instance.getEventsForSchoolWithID(userSchoolID) { (events) in
                            self.events.append(contentsOf: events)
                            self.tableView.reloadData()
                        }
                    } else {
                        // Couldn't get the user's school ID.
                        self.showErrorAlert(message: "Database error: Couldn't retrieve your school's events.")
                    }
                }
            } else {
                // User is not logged in, so present SignInVC
                print("Brennan - EventListVC auth listener in viewDidLoad says nobody is signed in!")
                self.events.removeAll()
                self.presentSignInVC(completion: {
                    print("Brennan - presented SignInVC")
                })
            }
        }
        // Auth.auth().removeStateDidChangeListener(handle)
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        
    }
    
    
    
    // MARK: Table View methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (filteredEvents != nil) ? self.filteredEvents!.count : self.events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventTableViewCell") as? EventTableViewCell
        let currEvent = (filteredEvents != nil) ? self.filteredEvents![indexPath.row] : self.events[indexPath.row]     // TODO: Change this array access because self.events will be a 2-D array eventually.
        if let thumbImageURL = currEvent.thumbnailURL {
            // The event has a thumbnail image.
            cell?.configureCell(event: currEvent, thumbnailImageFromCache: EventListVC.imageCache.object(forKey: thumbImageURL as NSString))
        } else {
            // The event doesn't have a thumbnail image.
            cell?.configureCell(event: currEvent)
        }
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
        self.view.endEditing(true)
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
        self.view.endEditing(true)
    }
    
    // Show the cancel button when the keyboard is visible.
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    // Hide the cancel button when the keyboard is not visible.
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    
    
    // MARK: Filtering and searching events
    
    func applyFilters() {
        if filtersOn {
            // Filter through all events
            self.filteredEvents = self.events
            for filter in filters! {
                self.filteredEvents = self.filteredEvents!.filter(filter)
            }
        }
    }
    
    func applySearch() {
        if searchOn {
            if filtersOn {
                // Search through already filtered events
                self.filteredEvents = self.filteredEvents?.filter { $0.name.lowercased().contains(searchText!.lowercased()) }
            } else {
                // Search through all events
                self.filteredEvents = self.events.filter { $0.name.lowercased().contains(searchText!.lowercased()) }
            }
        }
    }
    
    
    
    // MARK: Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "toFilterEventsVC":
                // Clear out existing filters and search.
                filters = nil
                searchBar.text = nil
                searchText = nil
            default:
                // Do nothing
                break
            }
        }
    }
    
    @IBAction func unwindFromFilterEventsTVC(sender: UIStoryboardSegue) {
        if let sourceVC = sender.source as? FilterEventsTVC, let newFilters = sourceVC.filtersCreated {
            self.filters = newFilters
        }
    }
    
    
    
    // MARK: Deinitializer
    
    // Remove the auth state listener when this VC is deallocated.
    deinit {
        if self.authListenerHandle != nil {
            Auth.auth().removeStateDidChangeListener(self.authListenerHandle!)
        }
    }
    
}
