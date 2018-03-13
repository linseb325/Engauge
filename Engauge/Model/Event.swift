//
//  Event.swift
//  Engauge
//
//  Created by Brennan Linse on 3/12/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import Foundation

struct Event {
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
    var associatedTransactionIDs: [String]?
}
