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
    Event(eventID: "eid4738264", name: "Harv's Birthday Party", description: "Drop in to wish your favorite dad a happy birthday! Dinner will be Harvey fries.", startTime: Date(timeIntervalSince1970: 1524762000), endTime: Date(timeIntervalSince1970: 1524780000), location: "Living Room", schedulerUID: "uid1", schoolID: "sid1", imageURL: "https://firebasestorage.googleapis.com/v0/b/engauge-519fe.appspot.com/o/profile-pics-full%2F2CE30441-D4F0-454F-BF32-63C36DB39669?alt=media&token=27969f5c-30fb-4bd1-8e54-33152d290a6f", thumbnailURL: "https://firebasestorage.googleapis.com/v0/b/engauge-519fe.appspot.com/o/profile-pics-thumbnail%2F2CE30441-D4F0-454F-BF32-63C36DB39669?alt=media&token=5809e7f3-c2eb-4969-880a-6ddadc1dfbd3", qrCodeURL: "", associatedTransactionIDs: ["tid1", "tid2", "tid3"]),
    Event(eventID: "eid39894805934", name: "Brennan's 22nd Birthday Party", description: "Drop in to wish your favorite brother a happy birthday! We'll be eating chili and watching March Madness. Later, there will be a heated game of Pictionary and a performance by Florence + The Machine. You won't want to miss it!", startTime: Date(timeIntervalSince1970: 1521990300), endTime: Date(timeIntervalSince1970: 1521994800), location: "Acuity Mutual Insurance Headquarters", schedulerUID: "uid1", schoolID: "sid1", imageURL: "https://firebasestorage.googleapis.com/v0/b/engauge-519fe.appspot.com/o/profile-pics-full%2FB3279C11-8713-4C20-BBB2-6DD2817D5385?alt=media&token=46169ec8-ffed-4043-bdf7-2201a47454e8", thumbnailURL: "https://firebasestorage.googleapis.com/v0/b/engauge-519fe.appspot.com/o/profile-pics-thumbnail%2FB3279C11-8713-4C20-BBB2-6DD2817D5385?alt=media&token=8454210c-4430-41d8-9ed1-6d65632b2ba0", qrCodeURL: "", associatedTransactionIDs: ["tid1", "tid2", "tid3"])
]



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
                         events: "events",
                         domain: "domain",
                         name: "name")
    
    static let TRANSACTION = (key: "transactions",
                              eventID: "eventID",
                              manualInitiatorUID: "manualInitiatorUID",
                              pointValue: "pointValue",
                              prizeID: "prizeID",
                              schoolID: "schoolID",
                              timestamp: "timestamp",
                              userID: "userID")
    
    static let USER_FAVORITE_EVENTS_KEY = "userFavoriteEvents"
    
    static let USER = (key: "users",
                       approvedForScheduler: "approvedForScheduler",
                       emailAddress: "emailAddress",
                       events: "events",
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
    static let EVENT_PICS_FULL = "event-pics-full"
    static let EVENT_PICS_THUMBNAIL = "event-pics-thumbnail"
}



struct StorageImageQuality {
    static let FULL: CGFloat = 1.0
    static let THUMBNAIL: CGFloat = 0.1
}







