//
//  SignInVC.swift
//  Engauge
//
//  Created by Brennan Linse on 3/2/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class SignInVC: UIViewController, UITextFieldDelegate {
    
    // MARK: Outlets
    @IBOutlet weak var emailTextField: UITextField! { didSet { emailTextField.delegate = self } }
    @IBOutlet weak var passwordTextField: UITextField! { didSet { passwordTextField.delegate = self } }
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let currUser = Auth.auth().currentUser {
            print("Brennan - found current user in SignInVC viewDidLoad: \(currUser.email!)")
            self.dismiss(animated: true, completion: {
                print("Brennan - dismissed SignInVC because there's already a current user")
            })
        } else {
            print("Brennan - no current user in SignInVC viewDidLoad")
        }
        
        self.dismissKeyboardWhenTappedOutside()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        /*
        // Sign out.
        do {
            try Auth.auth().signOut()
        } catch let signOutError {
            print("Brennan - error signing out: \(signOutError.localizedDescription)")
        }
        */
    }
    
    
    
    
    // MARK: Actions
    
    // Sign In
    @IBAction func signInButtonTapped(_ sender: UIButton) {
        self.view.endEditing(true)
        
        let errorAlert = UIAlertController(title: "Error", message: nil, preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        
        // Typed an e-mail address?
        guard let email = emailTextField.text, !email.isEmpty else {
            self.showErrorAlert(message: "E-mail is required to sign in.")
            return
        }
        
        // Typed a password?
        guard let password = passwordTextField.text, !password.isEmpty else {
            self.showErrorAlert(message: "Password is required to sign in.")
            return
        }
        
        // Try to sign in. Display an error message if necessary.
        AuthService.instance.signIn(email: email, password: password) { (errorMessage, user) in
            if errorMessage != nil {
                // There was a sign-in error.
                self.showErrorAlert(message: errorMessage!)
            } else {
                // Successfully signed in.
                
                // User object returned?
                guard let signedInUser = user else {
                    // Weird problem. Should never happen.
                    do {
                        try Auth.auth().signOut()
                    } catch let signOutError {
                        print("Brennan - error signing out: \(signOutError.localizedDescription)")
                    }
                    return
                }
                
                // Is the user's e-mail verified?
                guard signedInUser.isEmailVerified else {
                    // Tell the user to verify his/her e-mail. Resend the e-mail if necessary.
                    let notVerifiedAlert = UIAlertController(title: "Not verified", message: "Please verify your e-mail address.", preferredStyle: .alert)
                    notVerifiedAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                        // Sign out.
                        do {
                            try Auth.auth().signOut()
                        } catch let signOutError {
                            print("Brennan - error signing out: \(signOutError.localizedDescription)")
                        }
                    }))
                    notVerifiedAlert.addAction(UIAlertAction(title: "Resend e-mail", style: .default, handler: { (action) in
                        AuthService.instance.sendEmailVerification(toUser: signedInUser, completion: { (errorMessage, user) in
                            // Sign out.
                            do {
                                try Auth.auth().signOut()
                            } catch let signOutError {
                                print("Brennan - error signing out: \(signOutError.localizedDescription)")
                            }
                            
                            if errorMessage != nil {
                                errorAlert.message = errorMessage!
                                self.present(errorAlert, animated: true)
                            } else {
                                // Sent the verification e-mail.
                                print("Brennan - re-sent the verification e-mail.")
                            }
                        })
                    }))
                    self.present(notVerifiedAlert, animated: true)
                    
                    return
                }
                
                // If the user is a Scheduler, has he/she been approved for the role?
                DataService.instance.REF_USERS.child(signedInUser.uid).observeSingleEvent(of: .value, with: { (snapshot) in
                    // Can we verify the user's role?
                    guard let userData = snapshot.value as? [String : Any], let roleNum = userData[DBKeys.USER.role] as? Int else {
                        // Couldn't verify the user's role.
                        
                        // Sign out.
                        do {
                            try Auth.auth().signOut()
                        } catch let signOutError {
                            print("Brennan - error signing out: \(signOutError.localizedDescription)")
                        }
                        
                        self.showErrorAlert(message: "Database error: Couldn't verify your user role.")
                        return
                    }
                    
                    // Is the user a Scheduler?
                    if roleNum == UserRole.scheduler.toInt {
                        // Has the Scheduler been approved?
                        guard userData[DBKeys.USER.approvedForScheduler] as? Bool == true else {
                            // Scheduler hasn't been approved.
                            // Sign out.
                            do {
                                try Auth.auth().signOut()
                            } catch let signOutError {
                                print("Brennan - error signing out: \(signOutError.localizedDescription)")
                            }
                            
                            self.showErrorAlert(message: "Your school's Admin hasn't approved you for Scheduler status.")
                            return
                        }
                    }
                    
                    // PASSED ALL CHECKS
                    print("Brennan - sign-in successful. User is verified (and approved if a Scheduler).")
                    // TODO:
                    self.dismiss(animated: true) { print("Brennan - dismissed SignInVC because sign-in was successful.") }
                })
            }
        }
    }
    
    // Create Account
    @IBAction func createAccountButtonTapped(_ sender: UIButton) {
        dismissKeyboard()
    }
    
    
    
    
    // MARK: Keyboard
    
    // Dismiss the keyboard when the user taps the "return" button.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return true
    }
    
    
    
    
    // MARK: Deinitializer
    
    deinit {
        print("Deallocating an instance of SignInVC")
    }
    
}

