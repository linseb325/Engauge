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
    var currUserRoleNum: Int!
    
    static let storyboardIDs: [Int : [String]] = [
        UserRole.student.toInt : ["EventsPillar", "ProfilePillar", "ScanPillar", "PrizesPillar"],
        UserRole.scheduler.toInt : ["EventsPillar", "ProfilePillar", "PrizesPillar"],
        UserRole.admin.toInt : ["EventsPillar", "ProfilePillar", "TransactionsPillar", "RequestsPillar", "PrizesPillar"]
    ]
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            
            
            guard let currUser = user else {
                // Nobody is signed in!
                print("MyTabBarController knows I'm signed out")
                
                self?.dismiss(animated: true) {
                    print("Dismissed the tab bar controller.")
                }
                
                return
            }
            
            // Someone is signed in.
            
            DataService.instance.getRoleForUser(withUID: currUser.uid) { [weak self] (roleNum) in
                guard let currUserRoleNum = roleNum else {
                    // TODO: Show an alert that tells the user we couldn't verify his/her role. Then, sign out.
                    return
                }
                
                var pillars = [UIViewController]()
                
                switch currUserRoleNum {
                case UserRole.admin.toInt, UserRole.scheduler.toInt, UserRole.student.toInt:
                    if let storyboardIDs = MyTabBarController.storyboardIDs[currUserRoleNum] {
                        for id in storyboardIDs {
                            if let aPillar = self?.storyboard?.instantiateViewController(withIdentifier: id) {
                                print("Loaded pillar with ID: \(id)")
                                pillars.append(aPillar)
                            }
                        }
                        
                        self?.setViewControllers(pillars, animated: true)
                        
                    }
                    
                default:
                    break
                }
            }
        }
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
