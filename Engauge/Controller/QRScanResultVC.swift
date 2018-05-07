//
//  QRScanSuccessVC.swift
//  Engauge
//
//  Created by Brennan Linse on 5/4/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit

class QRScanSuccessVC: UIViewController {
    
    // MARK: Outlets
    
    @IBOutlet weak var thankYouLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var eventNameLabel: UILabel!
    @IBOutlet weak var earnedPointsLabel: UILabel!
    
    
    
    
    // MARK: Properties
    
    var eventID: String!
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DataService.instance.getEvent(withID: eventID) { (retrievedEvent) in
            self.updateUIForEvent(retrievedEvent)
        }
    }
    
    private func updateUIForEvent(_ event: Event?) {
        guard let event = event else {
            eventNameLabel.text = nil
            eventNameLabel.isHidden = true
            thankYouLabel.text = "Thank you for attending!"
            return
        }
        
        StorageService.instance.getImageForEvent(withID: event.eventID, thumbnail: true) { (eventImage) in
            if eventImage != nil {
                self.imageView.image = eventImage
            }
        }
        
        thankYouLabel.text = "Thank you for attending"
        eventNameLabel.text = event.name
        earnedPointsLabel.text = "You earned 1 point!"
    }
    
    
    
    
    // MARK: Deinitializer
    
    deinit {
        print("Deallocating an instance of QRScanResultVC")
    }
    
}
