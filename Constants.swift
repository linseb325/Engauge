//
//  Constants.swift
//  Engauge
//
//  Created by Brennan Linse on 3/3/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import Foundation
import UIKit



extension UIViewController {
    var contentsViewController: UIViewController {
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController ?? self
        } else {
            return self
        }
    }
    
    func dismissKeyboardWhenTappedOutside() {
        // If the user taps somewhere outside the keyboard while editing text, dismiss the keyboard.
        let tapOutsideKeyboard: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapOutsideKeyboard)
    }
    
    @objc private func dismissKeyboard() {
        self.view.endEditing(true)
    }
}



// User roles mapped to ints and strings
struct UserRole {
    static let student = (toInt: 0, toString: "student")
    static let scheduler = (toInt: 1, toString: "scheduler")
    static let admin = (toInt: 2, toString: "admin")
}

struct DatabaseKeys {
    static let EVENT = (key: "events",
                        associatedTransactions: "associatedTransactions",
                        description: "description",
                        endTime: "endTime",
                        imageURL: "imageURL",
                        location: "location",
                        name: "name",
                        qrCodeURL: "qrCodeURL",
                        schedulerUID: "schedulerUID",
                        schoolID: "schoolID",
                        startTime: "startTime",
                        thumbnailURL: "thumbnailURL")
    
    static let NOTIFICATION = (key: "notifications",
                               receiverUID: "receiverUID",
                               senderUID: "senderUID")
    
    static let PRIZE = (key: "prizes",
                        cost: "cost",
                        description: "description",
                        imageURL: "imageURL",
                        name: "name",
                        schoolID: "schoolID",
                        thumbnailURL: "thumbnailURL")
    
    static let SCHOOL = (key: "schools",
                         adminUID: "adminUID",
                         domain: "domain",
                         name: "name")
    
    static let TRANSACTION = (key: "transactions",
                              eventID: "eventID",
                              manualInitiator: "manualInitiator",
                              pointValue: "pointValue",
                              prizeID: "prizeID",
                              schoolID: "schoolID",
                              timestamp: "timestamp",
                              userID: "userID")
    
    static let USER = (key: "users",
                       approvedForScheduler: "approvedForScheduler",
                       emailAddress: "emailAddress",
                       events: "events",
                       favoriteEvents: "favoriteEvents",
                       firstName: "firstName",
                       imageURL: "imageURL",
                       lastName: "lastName",
                       notifications: "notifications",
                       pointBalance: "pointBalance",
                       role: "role",
                       schoolID: "schoolID",
                       thumbnailURL: "thumbnailURL")
}

struct StorageKeys {
    static let PROFILE_PICS_FULL = "profile-pics-full"
    static let PROFILE_PICS_THUMBNAIL = "profile-pics-thumbnail"
}

struct StorageImageQuality {
    static let FULL: CGFloat = 1.0
    static let THUMBNAIL: CGFloat = 0.1
}



// For use with expandable content (for example, table view cells)
protocol Expandable {
    var isExpanded: Bool { get set }
}




