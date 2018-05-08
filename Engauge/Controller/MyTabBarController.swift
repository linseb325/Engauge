//
//  MyTabBarController.swift
//  Engauge
//
//  Created by Brennan Linse on 3/16/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import FirebaseAuth

class MyTabBarController: UITabBarController {
    
    // MARK: Properties
    
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.authListenerHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            
            
            guard let currUser = user else {
                // Nobody is signed in!
                print("MyTabBarController knows I'm signed out")
                
                guard let signInVC = self.storyboard?.instantiateViewController(withIdentifier: "SignInVC") else {
                    fatalError("FATAL ERROR: Couldn't instantiate SignInVC from MyTabBarController.")
                }
                
                UIApplication.shared.keyWindow?.switchRootViewController(signInVC, animated: true, duration: 0.2, completion: {
                    print("Successfully switched the root view controller!")
                })
                return
            }
            
            // Someone is signed in.
            
            DataService.instance.getRoleForUser(withUID: currUser.uid) { (roleNum) in
                guard let currUserRoleNum = roleNum else {
                    // TODO: Show an alert that tells the user we couldn't verify his/her role. Then, sign out.
                    return
                }
                
                switch currUserRoleNum {
                case UserRole.student.toInt:
                    // Events, Profile, Scan, Prizes
                    break
                    
                case UserRole.scheduler.toInt:
                    // Events, Profile, Transactions, Prizes
                    break
                    
                case UserRole.admin.toInt:
                    // Events, Profile, Transactions, Requests, Prizes
                    break
                    
                default:
                    break
                }
                
                
                
            }
            
        }
        
        
        /*
        print("Brennan - number of windows: \(UIApplication.shared.windows.count)")
        
        // Is this the window's root view controller?
        if UIApplication.shared.windows[0].rootViewController === self {
            print("Brennan - window's root view controller is MyTabBarController")
        } else {
            print("Brennan - window's root view controller is NOT MyTabBarController")
        }
        */
    }
    
    
    
    
    // MARK: Removing the Auth Listener
    
    private func removeAuthListenerIfNecessary() {
        if authListenerHandle != nil {
            Auth.auth().removeStateDidChangeListener(authListenerHandle!)
            authListenerHandle = nil
        }
    }
    
    
    
    // MARK: Deinitializer
    
    deinit {
        print("Deallocating an instance of MyTabBarController")
        removeAuthListenerIfNecessary()
    }
    
}
