//
//  Event.swift
//  Engauge
//
//  Created by Brennan Linse on 3/12/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import Foundation

struct Event {
    var eventID: String
    var name: String
    var description: String?
    var startTime: Date
    var endTime: Date
    var location: String
    var schedulerUID: String
    var schoolID: String
    var imageURL: String?
    var thumbnailURL: String?
    var qrCodeURL: String
    
    
    // Returns an array containing database keys for which these two events have different values.
    static func differencesBetweenEvent(_ a: Event, andEvent b: Event) -> [String] {
        var keysWithDifferentValues = [String]()
        
        if a.eventID != b.eventID {
            keysWithDifferentValues.append(DBKeys.EVENT.key)
        }
        if a.name != b.name {
            keysWithDifferentValues.append(DBKeys.EVENT.name)
        }
        if a.description != b.description {
            keysWithDifferentValues.append(DBKeys.EVENT.description)
        }
        if a.startTime != b.startTime {
            keysWithDifferentValues.append(DBKeys.EVENT.startTime)
        }
        if a.endTime != b.endTime {
            keysWithDifferentValues.append(DBKeys.EVENT.endTime)
        }
        if a.location != b.location {
            keysWithDifferentValues.append(DBKeys.EVENT.location)
        }
        if a.schedulerUID != b.schedulerUID {
            keysWithDifferentValues.append(DBKeys.EVENT.schedulerUID)
        }
        if a.schoolID != b.schoolID {
            keysWithDifferentValues.append(DBKeys.EVENT.schoolID)
        }
        if a.imageURL != b.imageURL {
            keysWithDifferentValues.append(DBKeys.EVENT.imageURL)
        }
        if a.thumbnailURL != b.thumbnailURL {
            keysWithDifferentValues.append(DBKeys.EVENT.thumbnailURL)
        }
        if a.qrCodeURL != b.qrCodeURL {
            keysWithDifferentValues.append(DBKeys.EVENT.qrCodeURL)
        }
        return keysWithDifferentValues
    }
    
    
    
    
    
    
}
