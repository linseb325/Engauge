//
//  NotificationTableViewCell.swift
//  Engauge
//
//  Created by Brennan Linse on 5/1/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit

class NotificationTableViewCell: UITableViewCell {
    
    // MARK: Outlets
    
    @IBOutlet weak var theImageView: UIImageView!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    
    
    // MARK: Properties
    
    private var nameOfVC: String!
    
    // For formatting the notification's timestamp
    private static var timestampFormatter: DateFormatter = {
        let form = DateFormatter()
        form.timeStyle = .none
        form.dateStyle = .short
        form.setLocalizedDateFormatFromTemplate("MMMM d")
        return form
    }()
    
    
    
    
    // MARK: Configuring the Cell
    
    func configureCell(notification: EngaugeNotification, forVCWithTypeName nameOfVC: String) {
        self.nameOfVC = nameOfVC
        
        updateUI(forNotification: notification)
    }
    
    private func updateUI(forNotification notif: EngaugeNotification) {
        
        // Customize UI based on which screen is displaying this cell.
        switch nameOfVC {
            
        case "NotificationListTVC":
           // Get and display the sender's profile image.
            StorageService.instance.getImageForUser(withUID: notif.senderUID, thumbnail: true) { (senderProfileImage) in
                self.theImageView.image = senderProfileImage ?? UIImage(named: "avatar-square-gray")
            }
            // Get and display the sender's name.
            self.mainLabel.text = "Role Request"
            DataService.instance.getNameForUser(withUID: notif.senderUID) { (requesterName) in
                if requesterName != nil {
                    self.mainLabel.text! += ": \(requesterName!)"
                }
            }
            // Display when the notification was sent.
            if Calendar.current.isDateInToday(notif.timestamp) {
                self.detailLabel.text = "Today"
            } else if Calendar.current.isDateInYesterday(notif.timestamp) {
                self.detailLabel.text = "Yesterday"
            } else {
                self.detailLabel.text = NotificationTableViewCell.timestampFormatter.string(from: notif.timestamp)
            }
            
        default:
            break
        }
    }
    
}
