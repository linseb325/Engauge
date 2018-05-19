//
//  StorageService.swift
//  Engauge
//
//  Created by Brennan Linse on 3/8/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//
//  PURPOSE: Provide convenient methods for communicating with Firebase Storage.

import Foundation
import FirebaseStorage
import UIKit

class StorageService {
    
    // MARK: Shared Instance
    static let instance = StorageService()
    
    
    
    
    // MARK: References
    
    let REF_ROOT = Storage.storage().reference()
    
    let REF_PROFILE_PICS_FULL = Storage.storage().reference().child(StorageKeys.PROFILE_PICS_FULL)
    let REF_PROFILE_PICS_THUMBNAIL = Storage.storage().reference().child(StorageKeys.PROFILE_PICS_THUMBNAIL)
    let REF_EVENT_PICS_FULL = Storage.storage().reference().child(StorageKeys.EVENT_PICS_FULL)
    let REF_EVENT_PICS_THUMBNAIL = Storage.storage().reference().child(StorageKeys.EVENT_PICS_THUMBNAIL)
    let REF_QR_CODE_PICS = Storage.storage().reference().child(StorageKeys.QR_CODE_PICS)
    let REF_PRIZE_PICS = Storage.storage().reference().child(StorageKeys.PRIZE_PICS)
    
    
    
    
    // MARK: Retrieving Images
    func getImage(atStorageURL imageURL: String, withMaxSize maxBytes: Int64, completion: @escaping (UIImage?) -> Void) {
        Storage.storage().reference(forURL: imageURL).getData(maxSize: maxBytes) { (data, error) in
            guard error == nil, let imageData = data else {
                completion(nil)
                return
            }
            
            completion(UIImage(data: imageData))
        }
    }
    
    func getImageForPrize(withID prizeID: String, completion: @escaping (UIImage?) -> Void) {
        DataService.instance.REF_PRIZES.child(prizeID).child(DBKeys.PRIZE.imageURL).observeSingleEvent(of: .value) { (snapshot) in
            guard let prizeImageURL = snapshot.value as? String else {
                completion(nil)
                return
            }
            
            Storage.storage().reference(forURL: prizeImageURL).getData(maxSize: 2 * 1024 * 1024) { (data, error) in
                guard error == nil, let imageData = data else {
                    completion(nil)
                    return
                }
                
                completion(UIImage(data: imageData))
            }
        }
    }
    
    func getImageForUser(withUID uid: String, thumbnail: Bool, completion: @escaping (UIImage?) -> Void) {
        DataService.instance.REF_USERS.child(uid).child(thumbnail ? DBKeys.USER.thumbnailURL : DBKeys.USER.imageURL).observeSingleEvent(of: .value) { (snapshot) in
            guard let userImageURL = snapshot.value as? String else {
                completion(nil)
                return
            }
            
            Storage.storage().reference(forURL: userImageURL).getData(maxSize: 2 * 1024 * 1024) { (data, error) in
                guard error == nil, let imageData = data else {
                    completion(nil)
                    return
                }
                
                completion(UIImage(data: imageData))
            }
        }
    }
    
    func getImageForEvent(withID eventID: String, thumbnail: Bool, completion: @escaping (UIImage?) -> Void) {
        DataService.instance.REF_EVENTS.child(eventID).child(thumbnail ? DBKeys.EVENT.thumbnailURL : DBKeys.EVENT.imageURL).observeSingleEvent(of: .value) { (snapshot) in
            guard let eventImageURL = snapshot.value as? String else {
                completion(nil)
                return
            }
            
            Storage.storage().reference(forURL: eventImageURL).getData(maxSize: 2 * 1024 * 1024) { (data, error) in
                guard error == nil, let imageData = data else {
                    completion(nil)
                    return
                }
                
                completion(UIImage(data: imageData))
            }
        }
    }

    
    
    
    // MARK: Deleting Images
    
    func deleteImage(atURL imageURL: String, completion: ((String?) -> Void)? = nil) {
        Storage.storage().reference(forURL: imageURL).delete { (error) in
            completion?(error != nil ? self.messageForStorageError(error! as NSError) : nil)
        }
    }

    
    
    
    // MARK: Handling Errors
    
    func messageForStorageError(_ error: NSError) -> String {
        guard let errorCode = StorageErrorCode(rawValue: error.code) else {
            return "An unknown storage error occurred."
        }
        
        switch errorCode {
        case .objectNotFound:
            return "Failed to find a file in storage."
        default:
            return "A storage error occurred."
        }
    }
    
}
