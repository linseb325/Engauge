//
//  Constants.swift
//  Engauge
//
//  Created by Brennan Linse on 3/3/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//


import Foundation
import UIKit

// For displaying dates:
let WEEKDAY_INTS_TO_STRINGS_ABBREVIATED = [1:"Sun", 2:"Mon", 3:"Tue", 4:"Wed", 5:"Thu", 6:"Fri", 7:"Sat"]
let WEEKDAY_INTS_TO_STRINGS = [1:"Sunday", 2:"Monday", 3:"Tuesday", 4:"Wednesday", 5:"Thursday", 6:"Friday", 7:"Saturday"]

// Test event data:
let TEST_EVENTS = [
    Event(eventID: "eid4738264", name: "Harv's Birthday Party", description: "Drop in to wish your favorite dad a happy birthday! Dinner will be Harvey fries.", startTime: Date(timeIntervalSince1970: 1524762000), endTime: Date(timeIntervalSince1970: 1524780000), location: "Living Room", schedulerUID: "uid1", schoolID: "sid1", imageURL: "https://firebasestorage.googleapis.com/v0/b/engauge-519fe.appspot.com/o/profile-pics-full%2F2CE30441-D4F0-454F-BF32-63C36DB39669?alt=media&token=27969f5c-30fb-4bd1-8e54-33152d290a6f", thumbnailURL: "https://firebasestorage.googleapis.com/v0/b/engauge-519fe.appspot.com/o/profile-pics-thumbnail%2F2CE30441-D4F0-454F-BF32-63C36DB39669?alt=media&token=5809e7f3-c2eb-4969-880a-6ddadc1dfbd3", qrCodeURL: ""),
    Event(eventID: "eid39894805934", name: "Brennan's 22nd Birthday Party", description: "Drop in to wish your favorite brother a happy birthday! We'll be eating chili and watching March Madness. Later, there will be a heated game of Pictionary and a performance by Florence + The Machine. You won't want to miss it!", startTime: Date(timeIntervalSince1970: 1521990300), endTime: Date(timeIntervalSince1970: 1521994800), location: "Acuity Mutual Insurance Headquarters", schedulerUID: "uid1", schoolID: "sid1", imageURL: "https://firebasestorage.googleapis.com/v0/b/engauge-519fe.appspot.com/o/profile-pics-full%2FB3279C11-8713-4C20-BBB2-6DD2817D5385?alt=media&token=46169ec8-ffed-4043-bdf7-2201a47454e8", thumbnailURL: "https://firebasestorage.googleapis.com/v0/b/engauge-519fe.appspot.com/o/profile-pics-thumbnail%2FB3279C11-8713-4C20-BBB2-6DD2817D5385?alt=media&token=8454210c-4430-41d8-9ed1-6d65632b2ba0", qrCodeURL: "")
]



// User roles mapped to ints and strings
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




