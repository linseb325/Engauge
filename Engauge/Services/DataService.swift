//
//  DataService.swift
//  Engauge
//
//  Created by Brennan Linse on 3/6/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import Foundation
import FirebaseDatabase

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
    
    
    
    func getAllSchools(completion: @escaping ([School]) -> Void) {
        var schools = [School]()
        DataService.instance.REF_SCHOOLS.observeSingleEvent(of: .value) { (snapshot) in
            if let schoolsDict = snapshot.value as? [String: Any] {
                for schoolID in schoolsDict.keys {
                    if let schoolInfo = schoolsDict[schoolID] as? [String: Any] {
                        if let adminUID = schoolInfo[DatabaseKeys.SCHOOL.adminUID] as? String, let domain = schoolInfo[DatabaseKeys.SCHOOL.domain] as? String, let name = schoolInfo[DatabaseKeys.SCHOOL.name] as? String {
                            schools.append(School(name: name, schoolID: schoolID, adminUID: adminUID, domain: domain))
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
                print("Brennan - Database error trying to get school's info. snapshot.value = \(String(describing: snapshot.value))")
                completion?("Database error.")
                return
            }
            
            // Make sure the admin user exists in the "users" node of the database.
            DataService.instance.REF_USERS.child(adminUID).observeSingleEvent(of: .value, with: { (snapshot) in
                guard let adminInfo = snapshot.value as? [String : Any], adminInfo.count > 0 else {
                    print("Brennan - Database error trying to get admin's user info. snapshot.value = \(String(describing: snapshot.value))")
                    completion?("Database error.")
                    return
                }
                
                let notifID = DataService.instance.REF_NOTIFICATIONS.childByAutoId().key
                let notifData = [DatabaseKeys.NOTIFICATION.senderUID: senderUID,
                                 DatabaseKeys.NOTIFICATION.receiverUID: adminUID]
                let updates : [String : Any] = ["/\(DatabaseKeys.NOTIFICATION.key)/\(notifID)/": notifData,
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
    
    
    
    func handleFirebaseDatabaseError(_ error: NSError, completion: ((String?, Any?) -> Void)?) {
        // TODO: Do Firebase Database error codes exist? (i.e. Do I even need this function?)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
