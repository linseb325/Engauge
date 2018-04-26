//
//  EventTableViewCell.swift
//  Engauge
//
//  Created by Brennan Linse on 4/19/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase

class EventTableViewCell: UITableViewCell {
    
    // MARK: Outlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    
    
    // MARK: Properties
    
    var event: Event!
    private var nameOfVC: String!
    private var eventRef: DatabaseReference?
    
    static let formatter: DateFormatter = {
        let form = DateFormatter()
        form.dateStyle = .none
        form.timeStyle = .short
        return form
    }()
    
    // Date and time formats will be different depending on which screen is displaying these cells.
    private static let formats: [String : (dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style)] = [
        "EventListVC" : (.none, .short),
        "ProfileDetailsVC" : (.medium, .none)
    ]
    
    
    
    // MARK: Configuring the cell's UI
    
    func configureCell(event: Event, forVCWithTypeName nameOfVC: String = "EventListVC") {
        
        self.event = event
        self.nameOfVC = nameOfVC
        self.eventRef = DataService.instance.REF_EVENTS.child(event.eventID)
        
        attachDatabaseObserver()
    }
    
    private func updateUI(cacheImage: UIImage?) {
        self.configureDateAndTimeFormats(forVCWithName: nameOfVC)
        
        // Configure start time label text based on which screen is displaying this cell
        switch nameOfVC {
        case "EventListVC":
            self.startTimeLabel.text = "\(EventTableViewCell.formatter.string(from: event.startTime)) - \(EventTableViewCell.formatter.string(from: event.endTime))"
        case "ProfileDetailsVC":
            self.startTimeLabel.text = EventTableViewCell.formatter.string(from: event.startTime)
        default:
            self.startTimeLabel.text = EventTableViewCell.formatter.string(from: event.startTime)
        }
        
        // Set labels' text
        self.nameLabel.text = event.name
        self.locationLabel.text = event.location
        
        // Set the image passed in from the cache or download it from storage + add it to the cache.
        if let imageFromCache = cacheImage {
            // Passed in an image from the cache. No need to re-download it from Storage.
            self.thumbnailImageView.image = imageFromCache
        } else if let thumbImageURL = event.thumbnailURL {
            // We need to download the event's thumbnail image.
            Storage.storage().reference(forURL: thumbImageURL).getData(maxSize: 1 * 1024 * 1024, completion: { (data, error) in
                if error != nil {
                    // There was an error.
                    print("Brennan - there was an error downloading an event's thumbnail image from storage: \(error!.localizedDescription)")
                } else if let imageData = data, let retrievedImage = UIImage(data: imageData) {
                    self.thumbnailImageView.image = retrievedImage
                    EventListVC.imageCache.setObject(retrievedImage, forKey: thumbImageURL as NSString)
                }
            })
        } else {
            // This event doesn't have an associated image, so use the default image.
            self.thumbnailImageView.image = UIImage(named: "gauge")
        }
    }
    
    // Only works if eventRef is set
    private func attachDatabaseObserver() {
        self.eventRef?.observe(.value) { (snapshot) in
            if let eventData = snapshot.value as? [String : Any], let event = DataService.instance.eventFromSnapshotValues(eventData, withID: snapshot.key) {
                // Update the cell's UI whenever this event's data changes.
                self.event = event
                self.updateUI(cacheImage: EventListVC.imageCache.object(forKey: (event.thumbnailURL ?? "no-image-URL") as NSString))
            }
        }
    }
    
    private func configureDateAndTimeFormats(forVCWithName nameOfVC: String) {
        EventTableViewCell.formatter.dateStyle = EventTableViewCell.formats[nameOfVC]?.dateStyle ?? .none
        EventTableViewCell.formatter.timeStyle = EventTableViewCell.formats[nameOfVC]?.timeStyle ?? .none
    }
    
    
    
    
    
    
    deinit {
        self.eventRef?.removeAllObservers()
    }
}
