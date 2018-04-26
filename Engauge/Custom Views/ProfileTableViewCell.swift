//
//  ProfileTableViewCell.swift
//  Engauge
//
//  Created by Brennan Linse on 4/21/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

// TODO: When user data changes, the cell should update.

import UIKit
import FirebaseStorage

class ProfileTableViewCell: UITableViewCell {
    
    // MARK: Outlets
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    
    
    // MARK: Configuring the cell's UI
    
    func configureCell(user: EngaugeUser, thumbnailImageFromCache cacheImage: UIImage? = nil, forVCWithTypeName nameOfVC: String = "ProfileListVC") {
        
        // Customize the UI based on which screen is displaying this cell
        switch nameOfVC {
        case "ProfileListVC":
            break
        default:
            break
        }
        
        if cacheImage != nil {
            self.profileImageView.image = cacheImage!
        } else {
            Storage.storage().reference(forURL: user.thumbnailURL).getData(maxSize: 2 * 1024 * 1024) { (imgData, error) in
                if imgData != nil, error == nil, let thumbnail = UIImage(data: imgData!) {
                    self.profileImageView.image = thumbnail
                    ProfileListVC.imageCache.setObject(thumbnail, forKey: user.thumbnailURL as NSString)
                }
            }
        }
        
        self.mainLabel.text = "\(user.firstName) \(user.lastName)"
        self.detailLabel.text = UserRole.stringFromInt(user.role)?.capitalized
    }

    
    
    
    
}
