//
//  EventListVC.swift
//  Engauge
//
//  Created by Brennan Linse on 3/12/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

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
    
    // Observing database events
    private var refSchoolEventIDs: DatabaseReference?
    private var refAllEvents: DatabaseReference?
    private var eventDataChangedHandle: DatabaseHandle?
    private var eventAddedHandle: DatabaseHandle?
    private var eventRemovedHandle: DatabaseHandle?
    
    // Event data
    private var events = [Date : [Event]]() {
        didSet {
            sectionKeys = (filteredEvents == nil) ? events.keys.sorted() : filteredEvents!.keys.sorted()
        }
    }
    private var filteredEvents: [Date : [Event]]? {
        didSet {
            if filteredEvents != nil {
                sectionKeys = filteredEvents!.keys.sorted()
            } else {
                sectionKeys = events.keys.sorted()
            }
        }
    }
    private var sectionKeys = [Date]()
    
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("E, MMM d, yyyy")
        return f
    }()
    
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
            if let currUser = user {
                // User is logged in, so retrieve events.
                print("Brennan - EventListVC auth listener in viewDidLoad says current user's e-mail is: \(currUser.email ?? "nil")")
                
                // If the current user is a Scheduler or Admin, show the "add event" button.
                DataService.instance.getRoleForUser(withUID: currUser.uid) { (roleNum) in
                    if roleNum != nil {
                        switch roleNum! {
                        case UserRole.admin.toInt, UserRole.scheduler.toInt:
                            self.navigationItem.rightBarButtonItem = nil
                            let newEventButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.handleNewEventTapped))
                            self.navigationItem.rightBarButtonItem = newEventButton
                        default:
                            break
                        }
                    }
                }
                
                // Get the user's school ID and set up database observers.
                DataService.instance.getSchoolIDForUser(withUID: currUser.uid) { (schoolID) in
                    guard let userSchoolID = schoolID else {
                        self.showErrorAlert(message: "Database error: Couldn't verify your school's ID.")
                        return
                    }
                    
                    self.refAllEvents = DataService.instance.REF_EVENTS
                    self.refSchoolEventIDs = DataService.instance.REF_SCHOOL_EVENTS.child(userSchoolID)
                    self.attachDatabaseObservers()
                }
            } else {
                // User is not logged in, so present SignInVC
                print("Brennan - EventListVC auth listener in viewDidLoad says nobody is signed in!")
                self.events.removeAll()
                self.presentSignInVC(completion: { print("Brennan - presented SignInVC") })
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
    }
    
    
    
    
    // MARK: Table View methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return (filteredEvents != nil) ? self.filteredEvents!.count : self.events.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (filteredEvents != nil) ? (self.filteredEvents![sectionKeys[section]]!.count) : (self.events[sectionKeys[section]]!.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("EventTableViewCell", owner: self, options: nil)?.first as? EventTableViewCell
        let currEvent = (filteredEvents != nil) ? self.filteredEvents![sectionKeys[indexPath.section]]![indexPath.row] : self.events[sectionKeys[indexPath.section]]![indexPath.row]
        cell?.configureCell(event: currEvent, forVCWithTypeName: "EventListVC")
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return titleForSection(section)
    }
    
    // Helper for titleForHeaderInSection function above.
    // This function is only for English-speaking locales:
    func stringForWeekday(_ num: Int, abbreviated: Bool) -> String? {
        return abbreviated ? WEEKDAY_INTS_TO_STRINGS_ABBREVIATED[num] : WEEKDAY_INTS_TO_STRINGS[num]
    }
    
    // Helper for titleForHeaderInSection function above.
    func titleForSection(_ sectionNum: Int) -> String {
        let sectionDate = sectionKeys[sectionNum]
        return EventListVC.formatter.string(from: sectionDate)
    }
    
    // Tapped a table view cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectedEvent = (tableView.cellForRow(at: indexPath) as? EventTableViewCell)?.event {
            performSegue(withIdentifier: "toEventDetailsVC", sender: selectedEvent)
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
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
    
    
    
    
    // MARK: Filtering and searching events
    
    // Only affects the data model, not UI
    func applyFilters() {
        guard filtersOn else { return }
        
        var numFiltersApplied = 0
        self.filteredEvents = [Date : [Event]]()
        
        for filter in filters! {
            if numFiltersApplied > 0 {
                // The events have already been filtered once, so apply this filter to the sections in the already-filtered events.
                for daySection in filteredEvents! {
                    self.filteredEvents![daySection.key] = daySection.value.filter(filter)
                    // If all the events for a day are filtered out, remove that day from the filtered events.
                    if self.filteredEvents![daySection.key]!.isEmpty {
                        self.filteredEvents![daySection.key] = nil
                    }
                }
            } else {
                // This is the first filter we'll apply.
                // Go through each day's events and filter them with the current filter.
                for daySection in events {
                    self.filteredEvents![daySection.key] = daySection.value.filter(filter)
                    // If all the events for a day are filtered out, remove that day from the filtered events.
                    if self.filteredEvents![daySection.key]!.isEmpty {
                        self.filteredEvents![daySection.key] = nil
                    }
                }
                
            }
            numFiltersApplied += 1
        }
    }
    
    // Only affects the data model, not UI
    func applySearch() {
        guard searchOn else { return }
        
        if filtersOn {
            // Search through already filtered events
            for daySection in filteredEvents! {
                self.filteredEvents![daySection.key] = daySection.value.filter { $0.name.lowercased().contains(searchText!.lowercased()) }
                if self.filteredEvents![daySection.key]!.isEmpty {
                    self.filteredEvents![daySection.key] = nil
                }
            }
        } else {
            // Search through all events
            self.filteredEvents = [Date : [Event]]()
            for daySection in events {
                self.filteredEvents![daySection.key] = daySection.value.filter { $0.name.lowercased().contains(searchText!.lowercased()) }
                if self.filteredEvents![daySection.key]!.isEmpty {
                    self.filteredEvents![daySection.key] = nil
                }
            }
        }
    }
    
    
    
    
    // MARK: Bar button item actions
    
    // User wants to create a new event
    @objc private func handleNewEventTapped() {
        performSegue(withIdentifier: "toNewEventTVC", sender: nil)
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
            case "toEventDetailsVC":
                if let selectedEvent = sender as? Event, let destinationVC = segue.destination as? EventDetailsVC {
                    destinationVC.event = selectedEvent
                }
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
    
    
    
    
    // MARK: Observing Database Events
    
    // Only works if both database reference properties are set.
    private func attachDatabaseObservers() {
        // Some data for an event changed
        // TODO: This might become expensive because it fires every time ANY event's data changes, not just events at my school
        self.eventDataChangedHandle = self.refAllEvents?.observe(.childChanged) { (snapshot) in
            let eventID = snapshot.key
            if self.events.containsEvent(withID: eventID), let eventData = snapshot.value as? [String : Any], let updatedEvent = DataService.instance.eventFromSnapshotValues(eventData, withID: eventID) {
                self.events.removeEvent(withID: eventID)
                self.events.insertEvent(updatedEvent)
                self.applyFilters()
                self.applySearch()
                self.tableView.reloadData()
            }
        }
        
        // Event added for this school
        self.eventAddedHandle = self.refSchoolEventIDs?.observe(.childAdded) { (snapshot) in
            let eventAddedID = snapshot.key
            DataService.instance.getEvent(withID: eventAddedID) { (event) in
                if event != nil {
                    self.events.insertEvent(event!)
                    self.applyFilters()
                    self.applySearch()
                    self.tableView.reloadData()
                }
            }
        }
        
        // Event removed for this school
        self.eventRemovedHandle = self.refSchoolEventIDs?.observe(.childRemoved) { (snapshot) in
            let eventRemovedID = snapshot.key
            self.events.removeEvent(withID: eventRemovedID)
            self.applyFilters()
            self.applySearch()
            self.tableView.reloadData()
        }
    }
    
    private func removeDatabaseObserversIfNecessary() {
        if eventDataChangedHandle != nil {
            refAllEvents?.removeObserver(withHandle: eventDataChangedHandle!)
            eventDataChangedHandle = nil
        }
        if eventAddedHandle != nil {
            refSchoolEventIDs?.removeObserver(withHandle: eventAddedHandle!)
            eventAddedHandle = nil
        }
        if eventRemovedHandle != nil {
            refSchoolEventIDs?.removeObserver(withHandle: eventRemovedHandle!)
            eventRemovedHandle = nil
        }
    }
    
    private func removeAuthObserverIfNecessary() {
        if authListenerHandle != nil { Auth.auth().removeStateDidChangeListener(authListenerHandle!) }
    }
    
    
    
    // MARK: Deinitializer
    
    // Remove Database and Auth event listeners when this VC is deallocated.
    deinit {
        print("Deallocating an instance of EventListVC")
        removeAuthObserverIfNecessary()
        removeDatabaseObserversIfNecessary()
    }
    
}
