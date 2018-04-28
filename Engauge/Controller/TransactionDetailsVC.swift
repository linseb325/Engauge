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
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var pointValueLabel: UILabel!
    
    @IBOutlet weak var userNameButton: UIButton!
    @IBOutlet weak var transactionSourceLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var transactionIDLabel: UILabel!
    
    
    
    // MARK: Properties
    
    var transaction: Transaction!
    
    private static var dateFormatter: DateFormatter = {
        let form = DateFormatter()
        form.setLocalizedDateFormatFromTemplate("EEEE, MMMM d, y")
        return form
    }()
    
    private static var timeFormatter: DateFormatter = {
        let form = DateFormatter()
        form.setLocalizedDateFormatFromTemplate("h:mm:ss a")
        return form
    }()
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateUI()
    }
    
    
    
    
    // MARK: Updating the UI
    
    private func updateUI() {
        
        // Set an image based on this transaction's source.
        setAppropriateImage()
        
        // Set user name label
        DataService.instance.getNameForUser(withUID: transaction.userID) { (userFullName) in
            if userFullName != nil {
                self.userNameButton.setTitle(userFullName!, for: .normal)
            }
        }
        
        // Display timestamp and TID information in labels
        self.dateLabel.text = "on \(TransactionDetailsVC.dateFormatter.string(from: transaction.timestamp))"
        self.timeLabel.text = "at \(TransactionDetailsVC.timeFormatter.string(from: transaction.timestamp))"
        self.transactionIDLabel.text = "TID: \(transaction.transactionID)"
        
        
        // Configure the large top-right point value label
        let absoluteNumPoints = abs(transaction.pointValue)
        
        if transaction.pointValue != 0 {
            let isPositive = transaction.pointValue > 0
            pointValueLabel.text = "\(isPositive ? "+" : "-") \(absoluteNumPoints)"
            pointValueLabel.textColor = isPositive ? .green : .red
        } else {
            // Zero transaction
            pointValueLabel.text = "-"
            pointValueLabel.textColor = .black
        }
        
        var str = ""
        switch transaction.source {
            
        case .qrScan:
            str += "\(transaction.pointValue >= 0 ? "gained" : "lost") \(absoluteNumPoints) point\(absoluteNumPoints != 1 ? "s" : "")"
            DataService.instance.getNameOfEvent(withID: transaction.eventID!) { (eventName) in
                str += "\nfor attending \(eventName ?? "an event")"
                self.transactionSourceLabel.text = str
            }
            
        case .prizeRedemption:
            str += "\(transaction.pointValue > 0 ? "gained" : "redeemed") \(absoluteNumPoints) point\(absoluteNumPoints != 1 ? "s" : "")"
            DataService.instance.getNameOfPrize(withID: transaction.prizeID!) { (prizeName) in
                str += "\nfor: \(prizeName ?? "a prize")"
                self.transactionSourceLabel.text = str
            }
            
        case .manualInitiation:
            str += "\(transaction.pointValue >= 0 ? "gained" : "lost") \(absoluteNumPoints) point\(absoluteNumPoints != 1 ? "s" : "")"
            str += "\nvia a manual transaction"
            DataService.instance.getNameForUser(withUID: transaction.manualInitiatorUID!) { (manualInitiatorName) in
                str += "\ninitiated by \(manualInitiatorName ?? "an Admin")"
                self.transactionSourceLabel.text = str
            }
            break
        case .undetermined:
            break
        }
    }
    
    // Image will be different based on what type of event caused this transaction.
    private func setAppropriateImage() {
        switch transaction.source {
            
        case .qrScan:
            StorageService.instance.getImageForEvent(withID: transaction.eventID!, thumbnail: true) { (eventImage) in
                if eventImage != nil {
                    self.imageView.image = eventImage
                } else {
                    // TODO: Display a generic QR/event image.
                }
            }
            
        case .prizeRedemption:
            StorageService.instance.getImageForPrize(withID: transaction.prizeID!) { (prizeImage) in
                if prizeImage != nil {
                    self.imageView.image = prizeImage
                } else {
                    // TODO: Display a generic prize/redemption image.
                }
            }
            
        case .manualInitiation:
            StorageService.instance.getImageForUser(withUID: transaction.manualInitiatorUID!, thumbnail: true) { (adminImage) in
                if adminImage != nil {
                    self.imageView.image = adminImage
                } else {
                    self.imageView.image = UIImage(named: "avatar-square-gray")
                }
            }
            
        case .undetermined:
            imageView.image = UIImage(named: "gauge")
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
