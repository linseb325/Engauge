//
//  PrizeTableViewCell.swift
//  Engauge
//
//  Created by Brennan Linse on 5/5/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit

class PrizeTableViewCell: UITableViewCell {
    
    // MARK: Outlets
    
    @IBOutlet weak var prizeImageView: UIImageView!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var priceTagContainerView: UIView!
    @IBOutlet weak var priceTagImageView: UIImageView!
    @IBOutlet weak var priceStackView: UIStackView!
    @IBOutlet weak var priceLabel: UILabel!
    
    
    
    
    // MARK: Properties
    
    
    
    
    // MARK: Configuring UI
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Rotate the price labels so they match the rotation of the price tag icon
        let priceTagRotation: CGFloat = 35
        self.priceStackView.transform = CGAffineTransform(rotationAngle: priceTagRotation * CGFloat.pi / 180)
    }
    
    func configureCellForVC(withTypeName nameOfVC: String, prize: Prize) {
        
        if let cacheImage = PrizeListTVC.imageCache.object(forKey: prize.imageURL as NSString) {
            self.prizeImageView.image = cacheImage
        } else {
            StorageService.instance.getImageForPrize(withID: prize.prizeID) { (prizeImage) in
                if prizeImage != nil {
                    PrizeListTVC.imageCache.setObject(prizeImage!, forKey: prize.imageURL as NSString)
                    self.prizeImageView.image = prizeImage
                }
            }
        }
        
        mainLabel.text = prize.name
        
        if prize.quantityAvailable > 0 {
            // Available for purchase
            detailLabel.text = "\(prize.quantityAvailable) available"
        } else {
            // Sold out
            detailLabel.text = "SOLD OUT"
            detailLabel.textColor = .red
        }
        
        
        priceLabel.text = "\(prize.price)"
        
        
        switch nameOfVC {
        case "PrizeListTVC":
            break
        default:
            break
        }
    }
    
}
