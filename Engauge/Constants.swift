//
//  Constants.swift
//  Engauge
//
//  Created by Brennan Linse on 3/3/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//
//  PURPOSE: Define constants for repeated use throughout the app.


import Foundation
import UIKit

// For displaying dates:
let WEEKDAY_INTS_TO_STRINGS_ABBREVIATED = [1:"Sun", 2:"Mon", 3:"Tue", 4:"Wed", 5:"Thu", 6:"Fri", 7:"Sat"]
let WEEKDAY_INTS_TO_STRINGS = [1:"Sunday", 2:"Monday", 3:"Tuesday", 4:"Wednesday", 5:"Thursday", 6:"Friday", 7:"Saturday"]




/** User roles mapped to ints and strings */
struct UserRole {
    static let student = (toInt: 0, toString: "student")
    static let scheduler = (toInt: 1, toString: "scheduler")
    static let admin = (toInt: 2, toString: "admin")
    
    static func stringFromInt(_ roleInt: Int) -> String? {
        switch roleInt {
        case UserRole.student.toInt:
            return UserRole.student.toString
        case UserRole.scheduler.toInt:
            return UserRole.scheduler.toString
        case UserRole.admin.toInt:
            return UserRole.admin.toString
        default:
            return nil
        }
    }
    
}




/** Firebase Database keys */
struct DBKeys {
    struct EVENT {
        static let key = "events"
        static let associatedTransactions = "associatedTransactions"
        static let description = "description"
        static let endTime = "endTime"
        static let imageURL = "imageURL"
        static let location = "location"
        static let name = "name"
        static let qrCodeURL = "qrCodeURL"
        static let schedulerUID = "schedulerUID"
        static let schoolID = "schoolID"
        static let startTime = "startTime"
        static let thumbnailURL = "thumbnailURL"
    }
    
    static let EVENT_TRANSACTIONS_KEY = "eventTransactions"
    
    struct NOTIFICATION {
        static let key = "notifications"
        static let receiverUID = "receiverUID"
        static let senderUID = "senderUID"
        static let timestamp = "timestamp"
    }
    
    struct PRIZE {
        static let key = "prizes"
        static let price = "price"
        static let description = "description"
        static let imageURL = "imageURL"
        static let name = "name"
        static let quantityAvailable = "quantityAvailable"
        static let schoolID = "schoolID"
    }
    
    struct SCHOOL {
        static let key = "schools"
        static let adminUID = "adminUID"
        static let domain = "domain"
        static let name = "name"
    }
    
    static let SCHOOL_EVENTS_KEY = "schoolEvents"
    
    static let SCHOOL_PRIZES_KEY = "schoolPrizes"
    
    static let SCHOOL_TRANSACTIONS_KEY = "schoolTransactions"
    
    static let SCHOOL_USERS_KEY = "schoolUsers"
    
    struct TRANSACTION {
        static let key = "transactions"
        static let eventID = "eventID"
        static let manualInitiatorUID = "manualInitiatorUID"
        static let pointValue = "pointValue"
        static let prizeID = "prizeID"
        static let schoolID = "schoolID"
        static let timestamp = "timestamp"
        static let userID = "userID"
    }
    
    static let USER_EVENTS_KEY = "userEvents"
    
    static let USER_FAVORITE_EVENTS_KEY = "userFavoriteEvents"
    
    static let USER_EVENTS_ATTENDED_KEY = "userEventsAttended"
    
    static let USER_NOTIFICATIONS_KEY = "userNotifications"
    
    static let USER_TRANSACTIONS_KEY = "userTransactions"
    
    struct USER {
        static let key = "users"
        static let approvedForScheduler = "approvedForScheduler"
        static let emailAddress = "emailAddress"
        static let firstName = "firstName"
        static let imageURL = "imageURL"
        static let lastName = "lastName"
        static let pointBalance = "pointBalance"
        static let role = "role"
        static let schoolID = "schoolID"
        static let thumbnailURL = "thumbnailURL"
    }
}




/** Firebase Storage keys */
struct StorageKeys {
    static let PROFILE_PICS_FULL = "profile-pics-full"
    static let PROFILE_PICS_THUMBNAIL = "profile-pics-thumbnail"
    static let EVENT_PICS_FULL = "event-pics-full"
    static let EVENT_PICS_THUMBNAIL = "event-pics-thumbnail"
    static let QR_CODE_PICS = "qr-code-pics"
    static let PRIZE_PICS = "prize-pics"
}




struct StorageImageQuality {
    static let FULL: CGFloat = 1.0
    static let THUMBNAIL: CGFloat = 0.1
}




struct ManualTransaction {
    static let maxPoints = 100
    static let minPoints = 1
}




