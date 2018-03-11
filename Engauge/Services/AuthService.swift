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
    
    static let instance = AuthService()
    
    // Signing in. Completion parameters are an error message and a user.
    func signIn(email: String, password: String, completion: ((String?, User?) -> Void)?) {
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
    
    // Creating a new user. Completion parameters are an error message and a user.
    func createUser(email: String, password: String, completion: ((String?, User?) -> Void)?) {
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            if error != nil {
                // There was an error creating a new user account.
                self.handleFirebaseAuthError(error! as NSError, completion: completion)
            } else {
                // Successfully created a new user account.
                completion?(nil, user)
            }
        }
    }
    
    // Sending a verification e-mail.
    func sendEmailVerification(toUser user: User, completion: ((String?, User?) -> Void)?) {
        user.sendEmailVerification { (error) in
            if error != nil {
                self.handleFirebaseAuthError(error! as NSError, completion: completion)
            } else {
                completion?(nil, user)
            }
        }
    }
    
    // Error handling. Completion parameters are an error message and a user.
    func handleFirebaseAuthError(_ error: NSError, completion: ((String?, User?) -> Void)?) {
        // Convert to an auth error code.
        guard let errorCode = AuthErrorCode(rawValue: error.code) else {
            // Couldn't convert to an AuthErrorCode instance
            completion?("An unknown error occurred.", nil)
            return
        }
        
        // Send an error message back to the caller based on the error code.
        switch errorCode {
        case .invalidEmail:
            completion?("Invalid e-mail address.", nil)
        case .emailAlreadyInUse:
            completion?("There is already an account associated with that e-mail address.", nil)
        case .weakPassword:
            completion?("Password too weak. Must be at least 6 characters long.", nil)
        case .wrongPassword:
            completion?("Incorrect password.", nil)
        case .userNotFound:
            completion?("User not found.", nil)
        case .networkError:
            completion?("Network error. Try again later.", nil)
        case .internalError:
            completion?("Internal database error. Try again later.", nil)
        case .invalidRecipientEmail:
            completion?("There was an issue sending a verification e-mail: The recipient's e-mail address is invalid.", nil)
        case .invalidSender, .invalidMessagePayload:
            completion?("There was an issue sending a verification e-mail.", nil)
        default:
            completion?("There was an error with the authentication service.", nil)
        }
    }
    
    
    
    
    
    
    
}
