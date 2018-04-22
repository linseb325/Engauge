//
//  MyTabBarController.swift
//  Engauge
//
//  Created by Brennan Linse on 3/16/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit

class MyTabBarController: UITabBarController {
    
    deinit {
        print("Brennan - deallocating MyTabBarController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
}
