//
//  EventListVC.swift
//  Engauge
//
//  Created by Brennan Linse on 3/12/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit

class EventListVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    // MARK: Outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    
    // MARK: Properties
    
    // private var events: [[Event]] = [[Event](), [Event]()]
    private var events = [Event]()
    private var filteredEvents: [Event]?
    static var imageCache = NSCache<NSString, UIImage>()
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        searchBar.delegate = self
        
        DataService.instance.getEventsForSchoolWithID("sid1") { (events) in
            self.events = events
            self.tableView.reloadData()
        }
        
    }
    
    
    
    // MARK: Table View methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventTableViewCell") as? EventTableViewCell
        let currEvent = self.events[indexPath.row]  // TODO: Change this array access because self.events will be a 2-D array eventually.
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
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text, !searchText.isEmpty else {
            self.filteredEvents = nil
            return
        }
        
        self.filteredEvents = self.events.filter { $0.name.lowercased().contains(searchText) }
    }
    
    
    
    
    
    
    
}
