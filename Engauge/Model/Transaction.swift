//
//  Transaction.swift
//  Engauge
//
//  Created by Brennan Linse on 3/22/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import Foundation

struct Transaction {
    var transactionID: String
    var schoolID: String
    var userID: String
    var pointValue: Int
    var timestamp: Date
    var eventID: String?
    var prizeID: String?
    var manualInitiatorUID: String?
}
