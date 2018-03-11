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
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dismissKeyboardWhenTappedOutside()
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("Brennan - Current user = \(Auth.auth().currentUser?.email ?? "nil")")
    }
    
    
    
    // Sign In
    @IBAction func signInButtonTapped(_ sender: UIButton) {
        self.view.endEditing(true)
        
        let errorAlert = UIAlertController(title: "Error", message: nil, preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        
        // Typed an e-mail address?
        guard let email = emailTextField.text, email != "" else {
            errorAlert.message = "E-mail is required to sign in."
            self.present(errorAlert, animated: true)
            return
        }
        
        // Typed a password?
        guard let password = passwordTextField.text, password != "" else {
            errorAlert.message = "Password is required to sign in."
            self.present(errorAlert, animated: true)
            return
        }
        
        // Try to sign in. Display an error message if necessary.
        AuthService.instance.signIn(email: email, password: password) { (errorMessage, user) in
            if errorMessage != nil {
                // There was a sign-in error.
                errorAlert.message = errorMessage!
                self.present(errorAlert, animated: true)
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
                    notVerifiedAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    notVerifiedAlert.addAction(UIAlertAction(title: "Resend e-mail", style: .default, handler: { (action) in
                        AuthService.instance.sendEmailVerification(toUser: signedInUser, completion: { (errorMessage, user) in
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
                    guard let userData = snapshot.value as? [String : Any], let role = userData[DatabaseKeys.USER.role] as? Int else {
                        // Couldn't verify the user's role.
                        errorAlert.message = "Database error: Couldn't verify your user role."
                        self.present(errorAlert, animated: true)
                        return
                    }
                    
                    // Is the user a Scheduler?
                    if role == UserRole.scheduler.toInt {
                        // Has the Scheduler been approved?
                        guard userData[DatabaseKeys.USER.approvedForScheduler] as? Bool == true else {
                            errorAlert.message = "Your school's Admin hasn't approved you for Scheduler status."
                            self.present(errorAlert, animated: true)
                            return
                        }
                    }
                    
                    // PASSED ALL CHECKS
                    print("Brennan - sign-in successful. User is verified and approved if a Scheduler.")
                    self.dismiss(animated: true)
                })
            }
        }
    }
    
    // Create Account
    @IBAction func createAccountButtonTapped(_ sender: UIButton) {
        self.view.endEditing(true)
    }
    
    // Dismiss the keyboard when the user taps the "return" button.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
}

