//
//  TransactionTableViewCell.swift
//  Engauge
//
//  Created by Brennan Linse on 4/19/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit

class TransactionTableViewCell: UITableViewCell {
    
    // MARK: Outlets
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var pointValueLabel: UILabel!
    
    
    
    
    // MARK: Properties
    var transaction: Transaction!
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("E M/d/yyyy at h:m a")
        return f
    }()
    
    
    
    // MARK: Configuring the cell's UI
    
    func configureCell(transaction: Transaction, forVCWithTypeName nameOfVC: String = "EventDetailsVC") {
        self.transaction = transaction
        
        // Customize the UI based on which screen is displaying this cell
        switch nameOfVC {
        case "EventDetailsVC":
            DataService.instance.getNameForUser(withUID: transaction.userID) { (fullName) in
                self.mainLabel.text = fullName
            }
        case "ProfileDetailsVC":
            self.mainLabel.text = transaction.source.asString
        default:
            self.mainLabel.text = "Transaction"
        }
        
        DataService.instance.getNameForUser(withUID: transaction.userID) { (fullName) in
            self.mainLabel.text = fullName
        }
        
        self.detailLabel.text = TransactionTableViewCell.formatter.string(from: transaction.timestamp)
        
        if transaction.pointValue >= 0 {
            // Positive transaction
            self.pointValueLabel.text = "+\(transaction.pointValue)"
            self.pointValueLabel.textColor = UIColor.green
        } else {
            // Negative transaction
            self.pointValueLabel.text = "-\(abs(transaction.pointValue))"
            self.pointValueLabel.textColor = UIColor.red
        }
    }
}
