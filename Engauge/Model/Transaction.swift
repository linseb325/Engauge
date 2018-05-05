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
    
    var source: Source {
        switch (eventID != nil, prizeID != nil, manualInitiatorUID != nil) {
        case (true, false, false):
            return .qrScan
        case (false, true, false):
            return .prizeRedemption
        case (false, false, true):
            return .manualInitiation
        default:
            return .undetermined
        }
    }
    
    enum Source {
        case qrScan
        case prizeRedemption
        case manualInitiation
        case undetermined
        
        var asString: String {
            switch self {
            case .qrScan:
                return "QR Scan"
            case .prizeRedemption:
                return "Prize Redemption"
            case .manualInitiation:
                return "Manual Transaction"
            case .undetermined:
                return ""
            }
        }
    }
    
    static let VALUE_QR_SCAN = 1
    
    
    
}
