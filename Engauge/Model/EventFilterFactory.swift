//
//  EventFilterFactory.swift
//  Engauge
//
//  Created by Brennan Linse on 3/14/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import Foundation
import FirebaseAuth

struct EventFilterFactory {
    typealias EventFilter = (Event) -> (Bool)
    
    static let formatter = DateFormatter()
    
    
    
    // MARK: Creating date filters
    
    // Filter for events between startDate and endDate
    static func filterForEventsBetweenDates(_ startDate: Date, and endDate: Date) throws -> EventFilter {
        let start = startDate.firstMoment
        let end = endDate.lastMoment
        
        // Lower bound must be before upper bound
        guard start <= end else {
            throw DateFilterError.invalidDateBounds
        }
        
        return { $0.startTime >= start && $0.startTime <= end }
    }
    
    // Filter for events after startDate
    static func filterForEventsAfterDate(_ startDate: Date) throws -> EventFilter {
        let start = startDate.firstMoment
        return { $0.startTime >= start }
    }
    
    // Filter for events before endDate
    static func filterForEventsBeforeDate(_ endDate: Date) throws -> EventFilter {
        let end = endDate.lastMoment
        return { $0.startTime <= end }
    }
    
    
    
    // MARK: Creating a favorites filter

    // Returns a favorites filter
    static func filterForFavorites(inListOfEventIDs eventIDs: [String]) -> EventFilter {
        return { eventIDs.contains($0.eventID) }
    }
    
    
    
    // Possible errors for creating date filters
    enum DateFilterError: Error {
        case invalidDateBounds
        case dateConversionError        // Shouldn't happen anymore (Edited EventFilterFactory's static methods on 5/3/18)
    }
    
}
