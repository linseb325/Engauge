//
//  SignInVC.swift
//  Engauge
//
//  Created by Brennan Linse on 3/2/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import FirebaseAuth

class SignInVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dismissKeyboardWhenTappedOutside()
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    
    @IBAction func signInButtonTapped(_ sender: UIButton) {
        self.view.endEditing(true)
        
        // Make sure e-mail field is filled out
        guard let email = emailTextField.text, email != "" else {
            let alert = UIAlertController(title: "Error", message: "E-mail is required to sign in.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        // Make sure password field is filled out
        guard let password = passwordTextField.text, password != "" else {
            let alert = UIAlertController(title: "Error", message: "Password is required to sign in.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        // Try to sign in. Display an error message if necessary.
        AuthService.instance.signIn(email: email, password: password) { (errorMessage, data) in
            if errorMessage != nil {
                // Display the error message.
                let alert = UIAlertController(title: "Error", message: errorMessage!, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                // Successfully signed in.
                if let user = data as? User {
                    print("Brennan - Signed in successfully with user: \(user.email ?? "")")
                }
            }
        }
    }
    
    @IBAction func createAccountButtonTapped(_ sender: UIButton) {
        print("Brennan - tapped create account")
        self.view.endEditing(true)
        // TODO: Segue to the account creation screen
    }
    
    // Dismiss the keyboard when the user taps the "return" button.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
}

