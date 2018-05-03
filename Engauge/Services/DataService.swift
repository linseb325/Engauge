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
    let REF_EVENT_TRANSACTIONS = Database.database().reference().child(DBKeys.EVENT_TRANSACTIONS_KEY)
    let REF_NOTIFICATIONS = Database.database().reference().child(DBKeys.NOTIFICATION.key)
    let REF_PRIZES = Database.database().reference().child(DBKeys.PRIZE.key)
    let REF_SCHOOLS = Database.database().reference().child(DBKeys.SCHOOL.key)
    let REF_SCHOOL_EVENTS = Database.database().reference().child(DBKeys.SCHOOL_EVENTS_KEY)
    let REF_SCHOOL_PRIZES = Database.database().reference().child(DBKeys.SCHOOL_PRIZES_KEY)
    let REF_SCHOOL_TRANSACTIONS = Database.database().reference().child(DBKeys.SCHOOL_TRANSACTIONS_KEY)
    let REF_SCHOOL_USERS = Database.database().reference().child(DBKeys.SCHOOL_USERS_KEY)
    let REF_TRANSACTIONS = Database.database().reference().child(DBKeys.TRANSACTION.key)
    let REF_USER_EVENTS = Database.database().reference().child(DBKeys.USER_EVENTS_KEY)
    let REF_USER_EVENTS_ATTENDED = Database.database().reference().child(DBKeys.USER_EVENTS_KEY)
    let REF_USER_FAVORITE_EVENTS = Database.database().reference().child(DBKeys.USER_FAVORITE_EVENTS_KEY)
    let REF_USER_NOTIFICATIONS = Database.database().reference().child(DBKeys.USER_NOTIFICATIONS_KEY)
    let REF_USER_TRANSACTIONS = Database.database().reference().child(DBKeys.USER_TRANSACTIONS_KEY)
    let REF_USERS = Database.database().reference().child(DBKeys.USER.key)
    
    var REF_CURRENT_USER: DatabaseReference? {
        if let currentUser = Auth.auth().currentUser {
            return DataService.instance.REF_USERS.child(currentUser.uid)
        }
        return nil
    }
    
    
    
    
    
    // MARK: Users
    
    func getUsersForSchool(withID schoolID: String, completion: @escaping ([EngaugeUser]) -> Void) {
        DataService.instance.REF_SCHOOL_USERS.child(schoolID).observeSingleEvent(of: .value) { (snapshot) in
            guard let schoolUIDs = (snapshot.value as? [String : Any])?.keys, schoolUIDs.count > 0 else {
                completion([EngaugeUser]())
                return
            }
            
            DataService.instance.getUsers(withUIDs: Array(schoolUIDs)) { (users) in
                completion(users)
            }
        }
    }
    
    func getUsers(withUIDs uids: [String], completion: @escaping ([EngaugeUser]) -> Void) {
        var users = [EngaugeUser]()
        var usersToRetrieve = uids.count
        
        guard usersToRetrieve > 0 else {
            completion(users)
            return
        }
        
        for uid in uids {
            DataService.instance.getUser(withUID: uid) { (user) in
                if user != nil {
                    users.append(user!)
                }
                usersToRetrieve -= 1
                if usersToRetrieve <= 0 {
                    completion(users)
                }
            }
        }
    }
    
    func getUser(withUID uid: String, completion: @escaping (EngaugeUser?) -> Void) {
        DataService.instance.REF_USERS.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if let userData = snapshot.value as? [String : Any], let retrievedUser = DataService.instance.userFromSnapshotValues(userData, withUID: snapshot.key) {
                completion(retrievedUser)
            } else {
                completion(nil)
            }
        }
    }
    
    func userFromSnapshotValues(_ userData: [String : Any], withUID uid: String) -> EngaugeUser? {
        
        if let userFirstName = userData[DBKeys.USER.firstName] as? String,
            let userLastName = userData[DBKeys.USER.lastName] as? String,
            let userEmailAddress = userData[DBKeys.USER.emailAddress] as? String,
            let userRole = userData[DBKeys.USER.role] as? Int,
            let userSchoolID = userData[DBKeys.USER.schoolID] as? String,
            let userImageURL = userData[DBKeys.USER.imageURL] as? String,
            let userThumbnailURL = userData[DBKeys.USER.thumbnailURL] as? String {
            // Optional values for a user
            let userPointBalance = userData[DBKeys.USER.pointBalance] as? Int
            let userApprovedForScheduler = userData[DBKeys.USER.approvedForScheduler] as? Bool
            
            let retrievedUser = EngaugeUser(userID: uid, firstName: userFirstName, lastName: userLastName, emailAddress: userEmailAddress, role: userRole, schoolID: userSchoolID, imageURL: userImageURL, thumbnailURL: userThumbnailURL, pointBalance: userPointBalance, approvedForScheduler: userApprovedForScheduler)
            
            return retrievedUser
        } else {
            return nil
        }
    }
    
    
    // TODO: Test this function by creating a user
    func createUserInDatabase(withUID uid: String, forSchoolWithID schoolID: String, userInfo: [String : Any], completion: ((String?) -> Void)?) {
        
        let updates: [String : Any] = [
            "/\(DBKeys.USER.key)/\(uid)" : userInfo,
            "/\(DBKeys.SCHOOL_USERS_KEY)/\(schoolID)/\(uid)" : true
        ]
        
        DataService.instance.REF_ROOT.updateChildValues(updates) { (error, ref) in
            completion?(error != nil ? error!.localizedDescription : nil)
        }
    }
    
    
    
    func getRoleForUser(withUID uid: String, completion: @escaping (Int?) -> Void) {
        DataService.instance.REF_USERS.child("/\(uid)/\(DBKeys.USER.role)").observeSingleEvent(of: .value) { (snapshot) in
            completion(snapshot.value as? Int)
        }
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
    
    func getEmailAddressForUser(withUID uid: String, completion: @escaping (String?) -> Void) {
        DataService.instance.REF_USERS.child(uid).child(DBKeys.USER.emailAddress).observeSingleEvent(of: .value) { (snapshot) in
            completion(snapshot.value as? String)
        }
    }
    
    func getSchoolIDForUser(withUID uid: String, completion: @escaping (String?) -> Void) {
        DataService.instance.REF_USERS.child("/\(uid)/\(DBKeys.USER.schoolID)").observeSingleEvent(of: .value) { (snapshot) in
            completion(snapshot.value as? String)
        }
    }
    
    func updateUserData(_ userDataUpdates: [String : Any], forUserWithUID uid: String, completion: ((String?) -> Void)?) {
        DataService.instance.REF_USERS.child(uid).updateChildValues(userDataUpdates) { (error, ref) in
            completion?(error != nil ? "Database error: There was a problem updating the user data." : nil)
        }

    }
    
    
    
    // Schools are not sorted in any way
    func getAllSchools(completion: @escaping ([School]) -> Void) {
        var schools = [School]()
        DataService.instance.REF_SCHOOLS.observeSingleEvent(of: .value) { (snapshot) in
            if let schoolsDict = snapshot.value as? [String: Any] {
                for schoolID in schoolsDict.keys {
                    if let schoolInfo = schoolsDict[schoolID] as? [String: Any],
                        let adminUID = schoolInfo[DBKeys.SCHOOL.adminUID] as? String,
                        let domain = schoolInfo[DBKeys.SCHOOL.domain] as? String,
                        let name = schoolInfo[DBKeys.SCHOOL.name] as? String {
                        // eventIDs is nil because this data will be used for displaying the names of the schools, not their events
                        schools.append(School(name: name, schoolID: schoolID, adminUID: adminUID, domain: domain, eventIDs: nil))
                    }
                }
            }
            completion(schools)
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
                "/\(DBKeys.SCHOOL_EVENTS_KEY)/\(newEventSchoolID)/\(eventID)" : true,
                "/\(DBKeys.USER_EVENTS_KEY)/\(newEventSchedulerUID)/\(eventID)" : true
            ]
            
            DataService.instance.REF_ROOT.updateChildValues(updates) { (error, ref) in
                completion?(error != nil ? "Database error: There was a problem adding the new event to the database." : nil)
            }
        }
    }
    
    
    
    
    // MARK: Editing events
    
    func updateEventData(_ eventDataUpdates: [String : Any], forEventWithID eventID: String, completion: ((String?) -> Void)?) {
        DataService.instance.REF_EVENTS.child(eventID).updateChildValues(eventDataUpdates) { (error, ref) in
            completion?(error != nil ? "Database error: There was a problem updating the event data." : nil)
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
                // Converting Doubles to Dates
                let startTime = Date(timeIntervalSince1970: startTimeDouble)
                let endTime = Date(timeIntervalSince1970: endTimeDouble)
                
                let retrievedEvent = Event(eventID: eventID, name: name, description: description, startTime: startTime, endTime: endTime, location: location, schedulerUID: schedulerUID, schoolID: schoolID, imageURL: imageURL, thumbnailURL: thumbnailURL, qrCodeURL: qrCodeURL)
                
                completion(retrievedEvent)
            } else {
                completion(nil)
            }
        })
    }
    
    // Tries to build an Event object from a Firebase Database snapshot.
    func eventFromSnapshotValues(_ eventData: [String : Any], withID eventID: String) -> Event? {
        if let name = eventData[DBKeys.EVENT.name] as? String,
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
            // Converting Doubles to Dates
            let startTime = Date(timeIntervalSince1970: startTimeDouble)
            let endTime = Date(timeIntervalSince1970: endTimeDouble)
            
            let retrievedEvent = Event(eventID: eventID, name: name, description: description, startTime: startTime, endTime: endTime, location: location, schedulerUID: schedulerUID, schoolID: schoolID, imageURL: imageURL, thumbnailURL: thumbnailURL, qrCodeURL: qrCodeURL)
            
            return retrievedEvent
        } else {
            return nil
        }
    }
    
    func getEventsScheduledByUser(withUID schedulerUID: String, completion: @escaping ([Event]) -> Void) {
        DataService.instance.REF_USER_EVENTS.child(schedulerUID).observeSingleEvent(of: .value) { (snapshot) in
            guard let eventIDs = (snapshot.value as? [String : Any])?.keys else {
                completion([Event]())
                return
            }
            
            DataService.instance.getEvents(withIDs: Array(eventIDs)) { (events) in
                completion(events)
            }
        }
    }
    
    func getEvents(withIDs eventIDs: [String], completion: @escaping ([Event]) -> Void) {
        var events = [Event]()
        
        var eventsToRetrieve = eventIDs.count
        guard eventsToRetrieve > 0 else {
            completion(events)
            return
        }
        
        for eventID in eventIDs {
            DataService.instance.getEvent(withID: eventID) { (retrievedEvent) in
                if retrievedEvent != nil {
                    events.append(retrievedEvent!)
                }
                eventsToRetrieve -= 1
                if eventsToRetrieve <= 0 {
                    completion(events)
                }
            }
        }
    }
    
    // Retrieved events are not sorted in any way
    func getEventsForSchool(withID schoolID: String, completion: @escaping ([Event]) -> Void) {
        var events = [Event]()
        DataService.instance.REF_SCHOOL_EVENTS.child(schoolID).observeSingleEvent(of: .value) { (snapshot) in
            if let eventIDs = (snapshot.value as? [String : Any])?.keys, eventIDs.count > 0 {
                var eventsToRetrieve = eventIDs.count
                for eventID in eventIDs {
                    DataService.instance.getEvent(withID: eventID) { (event) in
                        if event != nil {
                            events.append(event!)
                        }
                        eventsToRetrieve -= 1
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
        DataService.instance.REF_SCHOOL_EVENTS.child(schoolID).observeSingleEvent(of: .value) { (snapshot) in
            if let eventIDs = (snapshot.value as? [String : Any])?.keys, eventIDs.count > 0 {
                var eventsToRetrieve = eventIDs.count
                for eventID in eventIDs {
                    DataService.instance.getEvent(withID: eventID) { (event) in
                        if event != nil {
                            allEvents.append(event!)
                        }
                        eventsToRetrieve -= 1
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
    
    
    
    
    // Deletes the event's data from the database and its images from storage.
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
            updates.updateValue(nil, forKey: "/\(DBKeys.SCHOOL_EVENTS_KEY)/\(eventToDelete.schoolID)/\(eventToDelete.eventID)")
            
            // Delete this event's ID from the scheduler's list of events
            updates.updateValue(nil, forKey: "/\(DBKeys.USER_EVENTS_KEY)/\(eventToDelete.schedulerUID)/\(eventToDelete.eventID)")
            
            // Delete this event's data from the events node
            updates.updateValue(nil, forKey: "/\(DBKeys.EVENT.key)/\(eventToDelete.eventID)")
            
            
            // Perform the updates to delete the event from the database.
            DataService.instance.REF_ROOT.updateChildValues(updates) { (error, ref) in
                guard error == nil else {
                    completion?("Database error: Unable to delete the event.")
                    return
                }
                
                // Database updates are complete. Now, delete the event's associated images from Storage.
                StorageService.instance.deleteImage(atURL: eventToDelete.qrCodeURL)
                if eventToDelete.imageURL != nil {
                    StorageService.instance.deleteImage(atURL: eventToDelete.imageURL!)
                }
                if eventToDelete.thumbnailURL != nil {
                    StorageService.instance.deleteImage(atURL: eventToDelete.thumbnailURL!)
                }
                completion?(nil)
            }
        }
        DataService.instance.REF_USERS.removeObserver(withHandle: queryForFavoriters)
    }
    
    func getNameOfEvent(withID eventID: String, completion: @escaping (String?) -> Void) {
        DataService.instance.REF_EVENTS.child(eventID).child(DBKeys.EVENT.name).observeSingleEvent(of: .value) { (snapshot) in
            completion(snapshot.value as? String)
        }
    }
    
    
    
    func wasEventScheduledByUser(withUID uid: String, eventID: String, completion: @escaping (Bool) -> Void) {
        DataService.instance.REF_USER_EVENTS.child("\(uid)/\(eventID)").observeSingleEvent(of: .value) { (snapshot) in
            if let dummyValue = snapshot.value as? Bool {
                completion(dummyValue)
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
    
    
    
    // MARK: Transactions
    
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
        
        guard transactionsToRetrieve > 0 else {
            completion(transactions)
            return
        }
        
        for transactionID in transactionIDs {
            DataService.instance.getTransaction(withID: transactionID) { (transaction) in
                if transaction != nil {
                    transactions.append(transaction!)
                }
                transactionsToRetrieve -= 1
                if transactionsToRetrieve <= 0 {
                    completion(transactions)
                }
            }
        }
    }
    
    func getTransactionsForUser(withUID uid: String, completion: @escaping ([Transaction]) -> Void) {
        DataService.instance.REF_USER_TRANSACTIONS.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            guard let transactionIDs = (snapshot.value as? [String : Any])?.keys, transactionIDs.count > 0 else {
                completion([Transaction]())
                return
            }
            
            DataService.instance.getTransactions(withIDs: Array(transactionIDs)) { (transactions) in
                completion(transactions)
            }
        }
    }
    
    func getTransactionIDsForEvent(withID eventID: String, completion: @escaping ([String]) -> Void) {
        DataService.instance.REF_EVENT_TRANSACTIONS.child(eventID).observeSingleEvent(of: .value) { (snapshot) in
            let theTIDs = Array((snapshot.value as? [String : Any])?.keys ?? [String : Any]().keys)
            completion(theTIDs)
        }
    }
    
    func getTransactionsForEvent(withID eventID: String, completion: @escaping ([Transaction]) -> Void) {
        DataService.instance.getTransactionIDsForEvent(withID: eventID) { (transactionIDs) in
            DataService.instance.getTransactions(withIDs: transactionIDs, completion: { (transactions) in
                completion(transactions)
            })
        }
    }
    
    
    
    
    
    
    // MARK: Prizes
    
    func getNameOfPrize(withID prizeID: String, completion: @escaping (String?) -> Void) {
        DataService.instance.REF_PRIZES.child(prizeID).child(DBKeys.PRIZE.name).observeSingleEvent(of: .value) { (snapshot) in
            completion(snapshot.value as? String)
        }
    }
    
    
    
    // MARK: Transactions
    
    enum TransResult {
        case success
        case notEnoughPoints
        case userIsNotStudent
        case databaseError
        case zeroTransaction
        case outsideNumPointsBounds
    }
    
    func performTransaction(withPointValue transactionPointValue: Int, toUserWithUID uid: String, forSchoolWithID schoolID: String, forEventWithID eventID: String?, forPrizeWithID prizeID: String?, withManualInitiatorUID manualInitiatorUID: String?, completion: @escaping (Bool) -> Void) {
        DataService.instance.addTransactionToDatabase(withPointValue: transactionPointValue, toUserWithUID: uid, forSchoolWithID: schoolID, forEventWithID: eventID, forPrizeWithID: prizeID, withManualInitiatorUID: manualInitiatorUID) { (databaseUpdatesSuccessful) in
            guard databaseUpdatesSuccessful else {
                completion(false)
                return
            }
            
            DataService.instance.changePointBalanceForUser(withUID: uid, byPointValue: transactionPointValue) { (balanceChangeSuccessful) in
                completion(balanceChangeSuccessful)
            }
        }
    }
    
    func changePointBalanceForUser(withUID uid: String, byPointValue transactionPointValue: Int, completion: @escaping (_ success: Bool) -> Void) {
        
        guard transactionPointValue != 0 else {
            completion(true)
            return
        }
        
        DataService.instance.REF_USERS.child(uid).child(DBKeys.USER.pointBalance).runTransactionBlock({ (balanceData) -> TransactionResult in
            if var pointBalance = balanceData.value as? Int {
                
                guard pointBalance >= 0, (pointBalance + transactionPointValue) >= 0 else {
                    // This transaction, if completed, would take the user's balance below zero. ABORT!
                    return TransactionResult.abort()
                }
                
                pointBalance += transactionPointValue
                
                balanceData.value = pointBalance
                return TransactionResult.success(withValue: balanceData)
            }
            return TransactionResult.abort()
            
        }, andCompletionBlock: { (error, success, snapshot) in
            completion(success)
        })
        
    }
    
    /**
     - Updates the following database nodes:
        - "transactions"
        - "userTransactions"
        - "schoolTransactions"
        - "eventTransactions" (IF NECESSARY)
        - "userEventsAttended" (IF NECESSARY)
     - Important: You must pass a non-nil value in for exactly ONE of these arguments: eventID, prizeID, manualInitiatorUID
     */
    func addTransactionToDatabase(withPointValue pointValue: Int, toUserWithUID uid: String, forSchoolWithID schoolID: String, forEventWithID eventID: String? = nil, forPrizeWithID prizeID: String? = nil, withManualInitiatorUID manualInitiatorUID: String? = nil, completion: @escaping (_ success: Bool) -> Void) {
        let transactionID = DataService.instance.REF_TRANSACTIONS.childByAutoId().key
        
        var updates: [String : Any] = [
            "\(DBKeys.USER_TRANSACTIONS_KEY)/\(uid)/\(transactionID)" : true,
            "\(DBKeys.SCHOOL_TRANSACTIONS_KEY)/\(schoolID)/\(transactionID)" : true
        ]
        
        var transactionData: [String : Any] = [
            DBKeys.TRANSACTION.pointValue : pointValue,
            DBKeys.TRANSACTION.userID : uid,
            DBKeys.TRANSACTION.schoolID : schoolID,
            DBKeys.TRANSACTION.timestamp : Date().timeIntervalSince1970.rounded()
        ]
        
        // What is causing this transaction to occur?
        switch (eventID, prizeID, manualInitiatorUID) {
            
        case (let eid?, nil, nil):
            // QR Scan
            transactionData[DBKeys.TRANSACTION.eventID] = eid
            updates["\(DBKeys.EVENT_TRANSACTIONS_KEY)/\(eid)/\(transactionID)"] = true
            updates["\(DBKeys.USER_EVENTS_ATTENDED_KEY)/\(uid)/\(eid)"] = true
            
        case (nil, let pid?, nil):
            // Prize Redemption
            transactionData[DBKeys.TRANSACTION.prizeID] = pid
            
        case (nil, nil, let manInitUID?):
            // Manual Transaction
            transactionData[DBKeys.TRANSACTION.manualInitiatorUID] = manInitUID
            
        default:
            // Invalid parameters
            completion(false)
            return
        }
        
        updates["\(DBKeys.TRANSACTION.key)/\(transactionID)"] = transactionData
        
        DataService.instance.REF_ROOT.updateChildValues(updates) { (error, ref) in
            completion(error == nil)
        }
    }
    
    
    
    
    // MARK: Notifications
    
    func sendRoleRequestNotification(fromUserWithUID senderUID: String, forSchoolWithID receiverSchoolID: String, completion: ((String?) -> Void)?) {
        // Grab the admin's UID.
        DataService.instance.REF_SCHOOLS.child(receiverSchoolID).observeSingleEvent(of: .value) { (snapshot) in
            // Can we grab the school's admin's UID?
            guard let schoolInfo = snapshot.value as? [String : Any], let adminUID = schoolInfo[DBKeys.SCHOOL.adminUID] as? String else {
                completion?("Database error. Unable to deliver the notification to the admin because the school's admin information was not found.")
                return
            }
            
            // Make sure the admin user exists in the "users" node of the database.
            DataService.instance.REF_USERS.child(adminUID).observeSingleEvent(of: .value) { (snapshot) in
                guard let adminInfo = snapshot.value as? [String : Any], adminInfo.count > 0 else {
                    completion?("Database error. Unable to deliver the notification to the admin because the admin's profile information was not found.")
                    return
                }
                
                let notifID = DataService.instance.REF_NOTIFICATIONS.childByAutoId().key
                let notifData: [String : Any] = [
                    DBKeys.NOTIFICATION.senderUID: senderUID,
                    DBKeys.NOTIFICATION.receiverUID: adminUID,
                    DBKeys.NOTIFICATION.timestamp: Date().timeIntervalSince1970
                    ]
                let updates: [String : Any] = [
                    "/\(DBKeys.NOTIFICATION.key)/\(notifID)/": notifData,
                    "/\(DBKeys.USER_NOTIFICATIONS_KEY)/\(adminUID)/\(notifID)": true
                ]
                
                DataService.instance.REF_ROOT.updateChildValues(updates) { (error, ref) in
                    if error != nil {
                        // Database error.
                        completion?("Database error. Unable to deliver the notification to the admin.")
                    } else {
                        // Successfully added the notification.
                        completion?(nil)
                    }
                }
            }
        }
    }
    
    /**
     - Deletes the notification data from these nodes:
        - "notifications"
        - "userNotifications"
     - Updates the boolean value for key "approvedForScheduler" under the requester's data under the "users" node.
     */
    func performUpdatesForRoleRequestDecision(forNotificationWithID notificationID: String, senderUID: String, receiverUID: String, approveUserForScheduler: Bool, completion: ((Bool) -> Void)? = nil) {
        
        let updates: [String : Any?] = [
            "\(DBKeys.NOTIFICATION.key)/\(notificationID)" : nil,
            "\(DBKeys.USER_NOTIFICATIONS_KEY)/\(receiverUID)/\(notificationID)" : nil,
            "\(DBKeys.USER.key)/\(senderUID)/\(DBKeys.USER.approvedForScheduler)" : approveUserForScheduler
        ]
        
        DataService.instance.REF_ROOT.updateChildValues(updates) { (error, ref) in
            completion?(error == nil)
        }
    }
    
    func getNotification(withID notifID: String, completion: @escaping (EngaugeNotification?) -> Void) {
        DataService.instance.REF_NOTIFICATIONS.child(notifID).observeSingleEvent(of: .value) { (snapshot) in
            guard let notifData = snapshot.value as? [String : Any], let retrievedNotif = DataService.instance.notificationFromSnapshotValues(notifData, andNotificationID: notifID) else {
                completion(nil)
                return
            }
            completion(retrievedNotif)
        }
    }
    
    func notificationFromSnapshotValues(_ notifData: [String : Any], andNotificationID notifID: String) -> EngaugeNotification? {
        guard let senderUID = notifData[DBKeys.NOTIFICATION.senderUID] as? String,
            let receiverUID = notifData[DBKeys.NOTIFICATION.receiverUID] as? String,
            let timestampAsDouble = notifData[DBKeys.NOTIFICATION.timestamp] as? Double else {
                return nil
        }
        
        return EngaugeNotification(notificationID: notifID, senderUID: senderUID, receiverUID: receiverUID, timestamp: Date(timeIntervalSince1970: timestampAsDouble))
    }
    
    
    
    
    
    
    // MARK: Handling errors
    
    func handleFirebaseDatabaseError(_ error: NSError, completion: ((String?, Any?) -> Void)?) {
        // TODO: Do Firebase Database error codes exist? (i.e. Do I even need this function?)
    }
    
    
    
    
    
    
}
