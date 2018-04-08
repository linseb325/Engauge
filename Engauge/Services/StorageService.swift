//
//  StorageService.swift
//  Engauge
//
//  Created by Brennan Linse on 3/8/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import Foundation
import FirebaseStorage

class StorageService {
    
    static let instance = StorageService()
    
    let REF_ROOT = Storage.storage().reference()
    
    let REF_PROFILE_PICS_FULL = Storage.storage().reference().child(StorageKeys.PROFILE_PICS_FULL)
    let REF_PROFILE_PICS_THUMBNAIL = Storage.storage().reference().child(StorageKeys.PROFILE_PICS_THUMBNAIL)
    let REF_EVENT_PICS_FULL = Storage.storage().reference().child(StorageKeys.EVENT_PICS_FULL)
    let REF_EVENT_PICS_THUMBNAIL = Storage.storage().reference().child(StorageKeys.EVENT_PICS_THUMBNAIL)
    let REF_QR_CODE_PICS = Storage.storage().reference().child(StorageKeys.QR_CODE_PICS)
    
    
    func deleteImage(atURL imageURL: String, completion: ((String?) -> Void)? = nil) {
        Storage.storage().reference(forURL: imageURL).delete { (error) in
            completion?(error != nil ? self.messageForStorageError(error! as NSError) : nil)
        }
    }
    
    
    
    
    
    
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
