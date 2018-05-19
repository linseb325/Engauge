//
//  SignInVC.swift
//  Engauge
//
//  Created by Brennan Linse on 3/2/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//
//  PURPOSE: Sign in with your Engauge credentials.

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
        
        dismissKeyboardWhenTappedOutside()
        
        guard let currUser = Auth.auth().currentUser else {
            // TODO: Nobody is signed in.
            return
        }
        
        // Someone is signed in.
        print("\(currUser.email!) is already signed in! Bypassing the sign-in screen.")
        
        DataService.instance.getRoleForUser(withUID: currUser.uid) { [weak self] (roleNum) in
            guard let currUserRoleNum = roleNum else {
                return
            }
            
            self?.navigateToMainTabBarControllerUI(withUserRoleNum: currUserRoleNum)
        }
    }
    
    
    
    
    // MARK: Actions
    
    // Sign In
    @IBAction func signInButtonTapped(_ sender: UIButton) {
        dismissKeyboard()
        
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
        
        // 1) Can I sign in?
        AuthService.instance.signIn(email: email, password: password) { [weak self] (errorMessage, user) in
            guard errorMessage == nil else {
                self?.showErrorAlert(message: errorMessage!)
                return
            }
            
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
            
            // 2) Is my e-mail verified?
            guard signedInUser.isEmailVerified else {
                // NOT VERIFIED
                // Tell the user to verify his/her e-mail. Resend the e-mail if necessary.
                let notVerifiedAlert = UIAlertController(title: "Not verified", message: "Please verify your e-mail address.", preferredStyle: .alert)
                
                // OK option
                notVerifiedAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                    // User is not verified. Sign out.
                    do {
                        try Auth.auth().signOut()
                    } catch let signOutError {
                        print("Brennan - error signing out: \(signOutError.localizedDescription)")
                    }
                }))
                
                // Resend option
                notVerifiedAlert.addAction(UIAlertAction(title: "Resend e-mail", style: .default, handler: { (action) in
                    AuthService.instance.sendEmailVerification(toUser: signedInUser, completion: { [weak self] (errorMessage, user) in
                        // Sign out.
                        do {
                            try Auth.auth().signOut()
                        } catch let signOutError {
                            print("Brennan - error signing out: \(signOutError.localizedDescription)")
                        }
                        
                        guard errorMessage == nil else {
                            errorAlert.message = errorMessage!
                            self?.present(errorAlert, animated: true)
                            return
                        }
                        
                        if errorMessage != nil {
                            errorAlert.message = errorMessage!
                            self?.present(errorAlert, animated: true)
                        } else {
                            // Sent the verification e-mail.
                            print("Brennan - re-sent the verification e-mail.")
                        }
                    })
                }))
                
                self?.present(notVerifiedAlert, animated: true)
                return
            }
            
            // 3) If I'm a Scheduler, have I been approved for the role?
            DataService.instance.REF_USERS.child(signedInUser.uid).observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                // Can we verify the user's role?
                guard let userData = snapshot.value as? [String : Any], let roleNum = userData[DBKeys.USER.role] as? Int else {
                    // Couldn't verify the user's role.
                    // Sign out.
                    do {
                        try Auth.auth().signOut()
                    } catch let signOutError {
                        print("Brennan - error signing out: \(signOutError.localizedDescription)")
                    }
                    
                    self?.showErrorAlert(message: "Database error: Couldn't verify your user role.")
                    return
                }
                
                // If this is a Scheduler, make sure he/she is approved for the role.
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
                        
                        self?.showErrorAlert(message: "Your school's Admin hasn't approved you for Scheduler status.")
                        return
                    }
                }
                
                // PASSED ALL CHECKS
                print("Brennan - sign-in successful. User is verified (and approved if a Scheduler).")
                
                self?.emailTextField.text = nil
                self?.passwordTextField.text = nil
                self?.navigateToMainTabBarControllerUI(withUserRoleNum: roleNum)
            })
            
        }
    }
    
    // Create Account
    @IBAction func createAccountButtonTapped(_ sender: UIButton) {
        dismissKeyboard()
    }
    
    private func navigateToMainTabBarControllerUI(withUserRoleNum currUserRoleNum: Int) {
        guard let tbc = self.storyboard?.instantiateViewController(withIdentifier: "MyTabBarController") as? MyTabBarController else {
            self.showErrorAlert(message: "There was an issue loading the home screen's UI.")
            return
        }
        
        tbc.currUserRoleNum = currUserRoleNum
        self.present(tbc, animated: true) {
            print("SignInVC presented MyTabBarController")
        }
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

