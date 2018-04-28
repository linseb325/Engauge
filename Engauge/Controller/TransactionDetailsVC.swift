//
//  TransactionDetailsVC.swift
//  Engauge
//
//  Created by Brennan Linse on 4/26/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import FirebaseDatabase

class TransactionDetailsVC: UIViewController {
    
    // MARK: Outlets
    
    
    
    
    
    
    
    
    // MARK: Properties
    
    var transaction: Transaction!
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
    }
    
    
    
    
    // MARK: Updating the UI
    
    private func updateUI() {
        
        switch transaction.source {
        case .qrScan:
            break
        case .prizeRedemption:
            break
        case .manualInitiation:
            break
        case .undetermined:
            break
        }
    }
    
    
    
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        default:
            break
        }
    }
    
    
    
    
    
    
    
    // MARK: Firebase Observers
    
    private func attachDatabaseObservers() {
        
    }
    
    
    
    
    // MARK: Removing Observers
    
    private func removeDatabaseObserversIfNecessary() {
        
    }
    
    
    
    
    
    // MARK: Deinitializer
    
    deinit {
        
    }
}
