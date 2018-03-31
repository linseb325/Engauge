//
//  DataService.swift
//  Engauge
//
//  Created by Brennan Linse on 3/6/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

class DataService {
    
    static let instance = DataService()
    
    // Root database reference
    let REF_ROOT = Database.database().reference()
    
    // References to the root's immediate children
    let REF_EVENTS = Database.database().reference().child(DBKeys.EVENT.key)
    let REF_NOTIFICATIONS = Database.database().reference().child(DBKeys.NOTIFICATION.key)
    let REF_PRIZES = Database.database().reference().child(DBKeys.PRIZE.key)
    let REF_SCHOOLS = Database.database().reference().child(DBKeys.SCHOOL.key)
    let REF_TRANSACTIONS = Database.database().reference().child(DBKeys.TRANSACTION.key)
    let REF_USER_FAVORITE_EVENTS = Database.database().reference().child(DBKeys.USER_FAVORITE_EVENTS_KEY)
    let REF_USERS = Database.database().reference().child(DBKeys.USER.key)
    
    var REF_CURRENT_USER: DatabaseReference? {
        if let currentUser = Auth.auth().currentUser {
            return DataService.instance.REF_USERS.child(currentUser.uid)
        }
        return nil
    }
    
    
    
    func createUserInDatabase(uid: String, userInfo: [String : Any], completion: ((String?) -> Void)?) {
        DataService.instance.REF_USERS.child(uid).updateChildValues(userInfo) { (error, ref) in
            if error != nil {
                // An error occurred while adding the user to the database.
                completion?(error!.localizedDescription)     // TODO: Is the localized description suitable to display to the user?
            } else {
                // Successfully added the user to the database.
                completion?(nil)
            }
        }
    }
    
    
    
    func getRoleForUser(withUID uid: String, completion: @escaping (Int?) -> Void) {
        DataService.instance.REF_USERS.child("/\(uid)/\(DBKeys.USER.role)").observeSingleEvent(of: .value) { (snapshot) in
            if let role = snapshot.value as? Int {
                completion(role)
            } else {
                completion(nil)
            }
        }
    }
    
    func getSchoolIDForUser(withUID uid: String, completion: @escaping (String?) -> Void) {
        DataService.instance.REF_USERS.child("/\(uid)/\(DBKeys.USER.schoolID)").observeSingleEvent(of: .value) { (snapshot) in
            if let schoolID = snapshot.value as? String {
                completion(schoolID)
            } else {
                completion(nil)
            }
        }
    }
    
    
    
    // Event IDs are not sorted in any way
    func getFavoriteEventIDsForUser(withUID uid: String, completion: @escaping ([String]?) -> Void) {
        DataService.instance.REF_USER_FAVORITE_EVENTS.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if let favorites = snapshot.value as? [String : Bool], favorites.count > 0 {
                let favoriteIDs = Array(favorites.keys)
                completion(favoriteIDs)
            } else {
                completion(nil)
            }
        }
    }
    
    
    
    // Schools are not sorted in any way
    func getAllSchools(completion: @escaping ([School]) -> Void) {
        var schools = [School]()
        DataService.instance.REF_SCHOOLS.observeSingleEvent(of: .value) { (snapshot) in
            if let schoolsDict = snapshot.value as? [String: Any] {
                for schoolID in schoolsDict.keys {
                    if let schoolInfo = schoolsDict[schoolID] as? [String: Any] {
                        if let adminUID = schoolInfo[DBKeys.SCHOOL.adminUID] as? String, let domain = schoolInfo[DBKeys.SCHOOL.domain] as? String, let name = schoolInfo[DBKeys.SCHOOL.name] as? String {
                            // eventIDs is nil because this data will be used for displaying the names of the schools, not their events
                            schools.append(School(name: name, schoolID: schoolID, adminUID: adminUID, domain: domain, eventIDs: nil))
                        }
                    }
                }
            }
            completion(schools)
        }
    }
    
    
    
    
    // MARK: Creating notifications
    
    func sendRoleRequestNotification(fromUserWithUID senderUID: String, forSchoolWithID receiverSchoolID: String, completion: ((String?) -> Void)?) {
        // Grab the admin's UID.
        DataService.instance.REF_SCHOOLS.child(receiverSchoolID).observeSingleEvent(of: .value) { (snapshot) in
            // Can we grab the school's admin's UID?
            guard let schoolInfo = snapshot.value as? [String : Any], let adminUID = schoolInfo[DBKeys.SCHOOL.adminUID] as? String else {
                completion?("Database error. Unable to deliver the notification to the Admin.")
                return
            }
            
            // Make sure the admin user exists in the "users" node of the database.
            DataService.instance.REF_USERS.child(adminUID).observeSingleEvent(of: .value, with: { (snapshot) in
                guard let adminInfo = snapshot.value as? [String : Any], adminInfo.count > 0 else {
                    completion?("Database error. Unable to deliver the notification to the Admin.")
                    return
                }
                
                let notifID = DataService.instance.REF_NOTIFICATIONS.childByAutoId().key
                let notifData = [DBKeys.NOTIFICATION.senderUID: senderUID,
                                 DBKeys.NOTIFICATION.receiverUID: adminUID]
                let updates: [String : Any] = ["/\(DBKeys.NOTIFICATION.key)/\(notifID)/": notifData,
                               "/\(DBKeys.USER.key)/\(adminUID)/\(DBKeys.USER.notifications)/\(notifID)/": true]
                
                DataService.instance.REF_ROOT.updateChildValues(updates, withCompletionBlock: { (error, ref) in
                    if error != nil {
                        // Database error.
                        completion?("Database error. Unable to deliver the notification to the Admin.")
                    } else {
                        // Successfully added the notification.
                        completion?(nil)
                    }
                })
            })
        }
    }
    
    
    
    
    // MARK: Creating events
    
    func createEvent(withID eventID: String, eventData: [String : Any], completion: ((String?) -> Void)?) {
        // TODO: Error check: Make sure eventData doesn't contain any invalid database keys.
        
        guard let newEventSchedulerUID = eventData[DBKeys.EVENT.schedulerUID] as? String else {
            completion?("Database error: Couldn't verify the scheduler UID for the new event.")
            return
        }
        
        DataService.instance.getSchoolIDForUser(withUID: newEventSchedulerUID) { (schoolID) in
            guard let newEventSchoolID = schoolID else {
                completion?("Database error: Couldn't verify the scheduler's school ID.")
                return
            }
            
            let updates: [String : Any] = [
                "/\(DBKeys.EVENT.key)/\(eventID)" : eventData,
                "/\(DBKeys.SCHOOL.key)/\(newEventSchoolID)/\(DBKeys.SCHOOL.events)/\(eventID)" : true,
                "/\(DBKeys.USER.key)/\(newEventSchedulerUID)/\(DBKeys.USER.events)/\(eventID)" : true
            ]
            
            DataService.instance.REF_ROOT.updateChildValues(updates) { (error, ref) in
                completion?(error != nil ? "Database error: There was an issue adding the new event to the database." : nil)
            }
            
        }
        
        
        
        
    }
    
    
    
    
    // MARK: Retrieving and deleting events
    
    func getEvent(withID eventID: String, completion: @escaping (Event?) -> Void) {
        DataService.instance.REF_EVENTS.child(eventID).observeSingleEvent(of: .value, with: { (snapshot) in
            if let eventData = snapshot.value as? [String : Any],
                let name = eventData[DBKeys.EVENT.name] as? String,
                let startTimeDouble = eventData[DBKeys.EVENT.startTime] as? Double,
                let endTimeDouble = eventData[DBKeys.EVENT.endTime] as? Double,
                let location = eventData[DBKeys.EVENT.location] as? String,
                let schedulerUID = eventData[DBKeys.EVENT.schedulerUID] as? String,
                let schoolID = eventData[DBKeys.EVENT.schoolID] as? String,
                let qrCodeURL = eventData[DBKeys.EVENT.qrCodeURL] as? String {
                // Optional info for an event
                let description = eventData[DBKeys.EVENT.description] as? String
                let imageURL = eventData[DBKeys.EVENT.imageURL] as? String
                let thumbnailURL = eventData[DBKeys.EVENT.thumbnailURL] as? String
                let associatedTransactionIDs = Array((eventData[DBKeys.EVENT.associatedTransactions] as? [String : Any])?.keys ?? [String : Any]().keys)
                // Converting Doubles to Dates
                let startTime = Date(timeIntervalSince1970: startTimeDouble)
                let endTime = Date(timeIntervalSince1970: endTimeDouble)
                
                let retrievedEvent = Event(eventID: eventID, name: name, description: description, startTime: startTime, endTime: endTime, location: location, schedulerUID: schedulerUID, schoolID: schoolID, imageURL: imageURL, thumbnailURL: thumbnailURL, qrCodeURL: qrCodeURL, associatedTransactionIDs: associatedTransactionIDs.isEmpty ? nil : associatedTransactionIDs)

                
                completion(retrievedEvent)
            } else {
                completion(nil)
            }
        })

    }
    
    // Retrieved events are not sorted in any way
    func getEventsForSchool(withID schoolID: String, completion: @escaping ([Event]) -> Void) {
        var events = [Event]()
        DataService.instance.REF_SCHOOLS.child(schoolID).child(DBKeys.SCHOOL.events).observeSingleEvent(of: .value) { (snapshot) in
            if let eventIDs = (snapshot.value as? [String : Any])?.keys {
                var eventsToRetrieve = eventIDs.count
                for eventID in eventIDs {
                    DataService.instance.getEvent(withID: eventID) { (event) in
                        eventsToRetrieve -= 1
                        if event != nil {
                            events.append(event!)
                        }
                        if eventsToRetrieve <= 0 {
                            completion(events)
                        }
                    }
                }
            } else {
                completion(events)
            }
        }
    }
    
    func getEventsSectionedByDateForSchool(withID schoolID: String, completion: @escaping ([Date : [Event]]) -> Void) {
        var allEvents = [Event]()
        DataService.instance.REF_SCHOOLS.child(schoolID).child(DBKeys.SCHOOL.events).observeSingleEvent(of: .value) { (snapshot) in
            if let eventIDs = (snapshot.value as? [String : Any])?.keys {
                var eventsToRetrieve = eventIDs.count
                for eventID in eventIDs {
                    DataService.instance.getEvent(withID: eventID) { (event) in
                        eventsToRetrieve -= 1
                        if event != nil {
                            allEvents.append(event!)
                        }
                        if eventsToRetrieve <= 0 {
                            // Done getting events
                            var groupedEvents = allEvents.groupedByDate
                            // Sort each day's events from earliest to latest start time.
                            for dateSection in groupedEvents {
                                groupedEvents[dateSection.key] = dateSection.value.sorted { $0.startTime < $1.startTime }
                            }
                            completion(groupedEvents)
                        }
                    }
                }
            } else {
                // Couldn't get any events. Pass an empty dictionary to the completion handler.
                completion([Date : [Event]]())
            }
        }
    }
    
    
    
    
    func deleteEvent(_ eventToDelete: Event, completion: ((String?) -> Void)?) {
        // Must delete event ID from the school's list of events, the EVENTS node, the user who scheduled the event, and from the favorites list of all users who have favorited the event.
        var updates = [String : Any?]()
        
        // FIXME: This query will become less and less efficient as the database grows.
        let queryForFavoriters = DataService.instance.REF_USER_FAVORITE_EVENTS.queryOrdered(byChild: eventToDelete.eventID).queryEqual(toValue: true).observe(.value) { (snapshot) in
            
            // Delete the event's ID from favorites for each user who favorited it
            if let favoriterUIDs = (snapshot.value as? [String : Any])?.keys, !favoriterUIDs.isEmpty {
                for favoriterUID in favoriterUIDs {
                    updates.updateValue(nil, forKey: "/\(DBKeys.USER_FAVORITE_EVENTS_KEY)/\(favoriterUID)/\(eventToDelete.eventID)")
                }
            }
            
            // Delete this event's ID from the school's list of events
            updates.updateValue(nil, forKey: "/\(DBKeys.SCHOOL.key)/\(eventToDelete.schoolID)/\(DBKeys.SCHOOL.events)/\(eventToDelete.eventID)")
            
            // Delete this event's ID from the scheduler's list of events
            updates.updateValue(nil, forKey: "/\(DBKeys.USER.key)/\(eventToDelete.schedulerUID)/\(DBKeys.USER.events)/\(eventToDelete.eventID)")
            
            // Delete this event's data from the events node
            updates.updateValue(nil, forKey: "/\(DBKeys.EVENT.key)/\(eventToDelete.eventID)")
            
            
            // Perform the updates to delete the event from the database.
            DataService.instance.REF_ROOT.updateChildValues(updates) { (error, ref) in
                if error != nil {
                    completion?("Database error: Unable to delete the event.")
                } else {
                    completion?(nil)
                }
            }
        }
        DataService.instance.REF_USERS.removeObserver(withHandle: queryForFavoriters)
        
        
        
    }
    
    
    
    func getNameForUser(withUID uid: String, completion: @escaping (String?) -> Void) {
        DataService.instance.REF_USERS.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if let userData = snapshot.value as? [String: Any],
                let firstName = userData[DBKeys.USER.firstName] as? String,
                let lastName = userData[DBKeys.USER.lastName] as? String {
                completion("\(firstName) \(lastName)")
            } else {
                completion(nil)
            }
        }
    }
    
    
    
    
    func wasEventScheduledByUser(withUID uid: String, eventID: String, completion: @escaping (Bool) -> Void) {
        DataService.instance.REF_USERS.child(uid).child(DBKeys.USER.events).observeSingleEvent(of: .value) { (snapshot) in
            if let userEventIDs = snapshot.value as? [String : Any] {
                completion(userEventIDs.keys.contains(eventID))
            } else {
                completion(false)
            }
        }
    }
    
    
    
    
    // MARK: Favorite events
    
    func isEventFavoritedByUser(withUID uid: String, eventID: String, completion: @escaping (Bool) -> Void) {
        DataService.instance.REF_USER_FAVORITE_EVENTS.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if let userFavoriteEvents = snapshot.value as? [String : Bool] {
                completion(userFavoriteEvents.keys.contains(eventID))
            } else {
                completion(false)
            }
        }
    }
    
    
    
    func setFavorite(_ shouldFavorite: Bool, eventWithID eventID: String, forUserWithUID uid: String, completion: ((String?) -> Void)?) {
        DataService.instance.REF_USER_FAVORITE_EVENTS.child(uid).updateChildValues([eventID : (shouldFavorite ? true : nil) as Any]) { (error, ref) in
            if error != nil {
                // An error occurred while favoriting or un-favoriting the event.
                completion?("Database error: Couldn't \(shouldFavorite ? "add this event to your favorites." : "remove this event from your favorites.")")
            } else {
                // Successfully favorited or un-favorited the event.
                completion?(nil)
            }
        }
    }
    
    
    
    
    // MARK: Retreiving transactions
    
    func getTransaction(withID transactionID: String, completion: @escaping (Transaction?) -> Void) {
        DataService.instance.REF_TRANSACTIONS.child(transactionID).observeSingleEvent(of: .value) { (snapshot) in
            if let transactionData = snapshot.value as? [String : Any],
                let schoolID = transactionData[DBKeys.TRANSACTION.schoolID] as? String,
                let userID = transactionData[DBKeys.TRANSACTION.userID] as? String,
                let pointValue = transactionData[DBKeys.TRANSACTION.pointValue] as? Int,
                let timestampDouble = transactionData[DBKeys.TRANSACTION.timestamp] as? Double {
                // Optional info for a transaction
                let eventID = transactionData[DBKeys.TRANSACTION.eventID] as? String
                let prizeID = transactionData[DBKeys.TRANSACTION.prizeID] as? String
                let manualInitiatorUID = transactionData[DBKeys.TRANSACTION.manualInitiatorUID] as? String
                // Converting Double to Date for timestamp
                let timestamp = Date(timeIntervalSince1970: timestampDouble)
                
                let retrievedTransaction = Transaction(transactionID: transactionID, schoolID: schoolID, userID: userID, pointValue: pointValue, timestamp: timestamp, eventID: eventID, prizeID: prizeID, manualInitiatorUID: manualInitiatorUID)
                
                completion(retrievedTransaction)
            } else {
                completion(nil)
            }
        }
    }
    
    
    
    func getTransactions(withIDs transactionIDs: [String], completion: @escaping ([Transaction]) -> Void) {
        var transactions = [Transaction]()
        var transactionsToRetrieve = transactionIDs.count
        for transactionID in transactionIDs {
            DataService.instance.getTransaction(withID: transactionID) { (transaction) in
                transactionsToRetrieve -= 1
                if transaction != nil {
                    transactions.append(transaction!)
                }
                if transactionsToRetrieve <= 0 {
                    completion(transactions)
                }
            }
        }
    }
    
    
    
    
    // MARK: Handling errors
    
    func handleFirebaseDatabaseError(_ error: NSError, completion: ((String?, Any?) -> Void)?) {
        // TODO: Do Firebase Database error codes exist? (i.e. Do I even need this function?)
    }
    
    
    
    
    
    
}
