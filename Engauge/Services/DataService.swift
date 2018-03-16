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
    let REF_EVENTS = Database.database().reference().child(DatabaseKeys.EVENT.key)
    let REF_NOTIFICATIONS = Database.database().reference().child(DatabaseKeys.NOTIFICATION.key)
    let REF_PRIZES = Database.database().reference().child(DatabaseKeys.PRIZE.key)
    let REF_SCHOOLS = Database.database().reference().child(DatabaseKeys.SCHOOL.key)
    let REF_TRANSACTIONS = Database.database().reference().child(DatabaseKeys.TRANSACTION.key)
    let REF_USERS = Database.database().reference().child(DatabaseKeys.USER.key)
    
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
    
    
    
    func getRoleForUserWithUID(_ uid: String, completion: @escaping (Int?) -> Void) {
        DataService.instance.REF_USERS.child("/\(uid)/\(DatabaseKeys.USER.role)").observeSingleEvent(of: .value) { (snapshot) in
            if let role = snapshot.value as? Int {
                completion(role)
            } else {
                completion(nil)
            }
        }
    }
    
    func getSchoolIDForUserWithUID(_ uid: String, completion: @escaping (String?) -> Void) {
        DataService.instance.REF_USERS.child("/\(uid)/\(DatabaseKeys.USER.schoolID)").observeSingleEvent(of: .value) { (snapshot) in
            if let schoolID = snapshot.value as? String {
                completion(schoolID)
            } else {
                completion(nil)
            }
        }
    }
    
    
    
    // Event IDs are not sorted in any way
    func getFavoriteEventIDsForUserWithUID(_ uid: String, completion: @escaping ([String]?) -> Void) {
        DataService.instance.REF_USERS.child("/\(uid)/\(DatabaseKeys.USER.favoriteEvents)").observeSingleEvent(of: .value) { (snapshot) in
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
                        if let adminUID = schoolInfo[DatabaseKeys.SCHOOL.adminUID] as? String, let domain = schoolInfo[DatabaseKeys.SCHOOL.domain] as? String, let name = schoolInfo[DatabaseKeys.SCHOOL.name] as? String {
                            // eventIDs is nil because this data will be used for displaying the names of the schools, not their events
                            schools.append(School(name: name, schoolID: schoolID, adminUID: adminUID, domain: domain, eventIDs: nil))
                        }
                    }
                }
            }
            completion(schools)
        }
    }
    
    
    
    func sendRoleRequestNotification(fromUserWithUID senderUID: String, forSchoolWithID receiverSchoolID: String, completion: ((String?) -> Void)?) {
        // Grab the admin's UID.
        DataService.instance.REF_SCHOOLS.child(receiverSchoolID).observeSingleEvent(of: .value) { (snapshot) in
            // Can we grab the school's admin's UID?
            guard let schoolInfo = snapshot.value as? [String : Any], let adminUID = schoolInfo[DatabaseKeys.SCHOOL.adminUID] as? String else {
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
                let notifData = [DatabaseKeys.NOTIFICATION.senderUID: senderUID,
                                 DatabaseKeys.NOTIFICATION.receiverUID: adminUID]
                let updates: [String : Any] = ["/\(DatabaseKeys.NOTIFICATION.key)/\(notifID)/": notifData,
                               "/\(DatabaseKeys.USER.key)/\(adminUID)/\(DatabaseKeys.USER.notifications)/\(notifID)/": true]
                
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
    
    
    
    // Events are not sorted in any way
    func getEventsForSchoolWithID(_ schoolID: String, completion: @escaping ([Event]) -> Void) {
        var events = [Event]()
        DataService.instance.REF_SCHOOLS.child(schoolID).child(DatabaseKeys.SCHOOL.events).observeSingleEvent(of: .value) { (snapshot) in
            if let eventIDs = (snapshot.value as? [String : Any])?.keys {
                var eventsToRetrieve = eventIDs.count
                for eventID in eventIDs {
                    DataService.instance.getEventWithID(eventID) { (event) in
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
    
    
    
    func getEventWithID(_ eventID: String, completion: @escaping (Event?) -> Void) {
        DataService.instance.REF_EVENTS.child(eventID).observeSingleEvent(of: .value, with: { (snapshot) in
            if let eventData = snapshot.value as? [String : Any],
               let name = eventData[DatabaseKeys.EVENT.name] as? String,
               let startTimeDouble = eventData[DatabaseKeys.EVENT.startTime] as? Double,
               let endTimeDouble = eventData[DatabaseKeys.EVENT.endTime] as? Double,
               let location = eventData[DatabaseKeys.EVENT.location] as? String,
               let schedulerUID = eventData[DatabaseKeys.EVENT.schedulerUID] as? String,
               let schoolID = eventData[DatabaseKeys.EVENT.schoolID] as? String,
               let qrCodeURL = eventData[DatabaseKeys.EVENT.qrCodeURL] as? String {
                // Optional info for an event
                let description = eventData[DatabaseKeys.EVENT.description] as? String
                let imageURL = eventData[DatabaseKeys.EVENT.imageURL] as? String
                let thumbnailURL = eventData[DatabaseKeys.EVENT.thumbnailURL] as? String
                let associatedTransactionIDs = Array((eventData[DatabaseKeys.EVENT.associatedTransactions] as? [String : Any])?.keys ?? [String : Any]().keys)
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
    
    
    
    
    func handleFirebaseDatabaseError(_ error: NSError, completion: ((String?, Any?) -> Void)?) {
        // TODO: Do Firebase Database error codes exist? (i.e. Do I even need this function?)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
