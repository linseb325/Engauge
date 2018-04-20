//
//  EventTableViewCell.swift
//  Engauge
//
//  Created by Brennan Linse on 4/19/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import FirebaseStorage

class EventTableViewCell: UITableViewCell {
    
    // MARK: Outlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    // MARK: Properties
    var event: Event!
    
    static let formatter: DateFormatter = {
        let form = DateFormatter()
        form.dateStyle = .none
        form.timeStyle = .short
        return form
    }()
    
    private static let formats: [String : (dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style)] = [
        "EventListVC" : (.none, .short),
        "ProfileDetailsVC" : (.medium, .none)
    ]
    
    // MARK: Configuring the cell's UI
    func configureCell(event: Event, thumbnailImageFromCache: UIImage? = nil, forVCWithTypeName nameOfVC: String = "EventListVC") {
        self.event = event
        
        self.configureDateAndTimeFormats(forVCWithName: nameOfVC)
        
        switch nameOfVC {
        case "EventListVC":
            self.startTimeLabel.text = "\(EventTableViewCell.formatter.string(from: event.startTime)) - \(EventTableViewCell.formatter.string(from: event.endTime))"
        case "ProfileDetailsVC":
            self.startTimeLabel.text = EventTableViewCell.formatter.string(from: event.startTime)
        default:
            self.startTimeLabel.text = EventTableViewCell.formatter.string(from: event.startTime)
        }
        
        self.nameLabel.text = event.name
        self.locationLabel.text = event.location
        
        if let imageFromCache = thumbnailImageFromCache {
            // Passed in an image from the cache. No need to re-download it from Storage.
            self.thumbnailImageView.image = imageFromCache
        } else if let thumbImageURL = event.thumbnailURL {
            // We need to download the event's thumbnail image.
            Storage.storage().reference(forURL: thumbImageURL).getData(maxSize: 1 * 1024 * 1024, completion: { (data, error) in
                if error != nil {
                    // There was an error.
                    print("Brennan - there was an error downloading an event's thumbnail image from storage: \(error!.localizedDescription)")
                } else if let imageData = data, let retrievedImage = UIImage(data: imageData) {
                    DispatchQueue.global().sync {
                        self.thumbnailImageView.image = retrievedImage
                    }
                    EventListVC.imageCache.setObject(retrievedImage, forKey: thumbImageURL as NSString)
                }
            })
        } else {
            // This event doesn't have an associated image, so use the default image.
            self.thumbnailImageView.image = UIImage(named: "gauge")
        }
    }
    
    
    
    
    private func configureDateAndTimeFormats(forVCWithName nameOfVC: String) {
        EventTableViewCell.formatter.dateStyle = EventTableViewCell.formats[nameOfVC]?.dateStyle ?? .none
        EventTableViewCell.formatter.timeStyle = EventTableViewCell.formats[nameOfVC]?.timeStyle ?? .none
    }
}
