//
//  TransactionTableViewCell.swift
//  Engauge
//
//  Created by Brennan Linse on 3/22/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit

class TransactionTableViewCell: UITableViewCell {
    
    // MARK: Outlets
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var pointValueLabel: UILabel!
    
    
    
    
    // MARK: Properties
    var transaction: Transaction!
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("E M/d/yyyy at h:m a")
        return f
    }()
    
    
    
    
    // MARK: Configuring the cell's UI
    
    func configureCell(transaction: Transaction) {
        self.transaction = transaction
        
        DataService.instance.getNameForUser(withUID: transaction.userID) { (fullName) in
            self.userNameLabel.text = fullName
        }
        
        self.timestampLabel.text = TransactionTableViewCell.formatter.string(from: transaction.timestamp)
        
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
