//
//  AuthService.swift
//  Engauge
//
//  Created by Brennan Linse on 3/2/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import Foundation
import FirebaseAuth

class AuthService {
    
    private static let _instance = AuthService()
    
    static var instance: AuthService {
        return _instance
    }
    
    
    func signIn(email: String, password: String, completion: ((String?, Any?) -> Void)?) {
        // Sign in stuff
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if error != nil {
                // There was a sign-in error.
                self.handleFirebaseAuthError(error! as NSError, completion: completion)
            } else {
                // Signed in successfully.
                completion?(nil, user)
            }
        }
    }
    
    func handleFirebaseAuthError(_ error: NSError, completion: ((String?, Any?) -> Void)?) {
        // Convert to an auth error code.
        guard let errorCode = AuthErrorCode(rawValue: error.code) else {
            // Couldn't convert to an AuthErrorCode instance
            completion?("An unknown error occurred during authentication.", nil)
            return
        }
        
        // Send an error message back to the caller based on the error code.
        switch errorCode {
        case .emailAlreadyInUse:
            completion?("There is already an account associated with that e-mail address.", nil)
        case .invalidEmail:
            completion?("Invalid e-mail address.", nil)
        case .wrongPassword:
            completion?("Incorrect password.", nil)
        case .userNotFound:
            completion?("User not found.", nil)
        default:
            completion?("There was an error during authentication.", nil)
        }
    }
    
    
    
    
    
    
    
}
