//
//  EngaugeNotification.swift
//  Engauge
//
//  Created by Brennan Linse on 5/1/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import Foundation

struct EngaugeNotification {
    var notificationID: String
    
    // The UID of the user who is requesting the role of scheduler.
    var senderUID: String
    
    // The UID of the admin who will respond to the role request notification.
    var receiverUID: String
    
    var timestamp: Date
}
