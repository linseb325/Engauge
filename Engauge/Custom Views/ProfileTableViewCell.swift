//
//  ProfileTableViewCell.swift
//  Engauge
//
//  Created by Brennan Linse on 4/21/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase

class ProfileTableViewCell: UITableViewCell {
    
    // MARK: Outlets
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    
    
    // MARK: Properties
    
    private var nameOfVC: String!
    private var userRef: DatabaseReference?
    
    
    
    // MARK: Configuring the cell's UI
    
    func configureCell(user: EngaugeUser, forVCWithTypeName nameOfVC: String = "ProfileListVC") {
        
        self.nameOfVC = nameOfVC
        self.userRef = DataService.instance.REF_USERS.child(user.userID)
        
        attachDatabaseObserver()
    }
    
    private func updateUI(user: EngaugeUser, cacheImage: UIImage?) {
        // Customize the UI based on which screen is displaying this cell
        switch nameOfVC {
        case "ProfileListVC":
            break
        default:
            break
        }
        
        // Show the image passed in from the cache or download it from storage + add it to the cache.
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
        
        // Update labels' text
        self.mainLabel.text = "\(user.firstName) \(user.lastName)"
        self.detailLabel.text = UserRole.stringFromInt(user.role)?.capitalized
    }
    
    // Only works if userRef is set
    private func attachDatabaseObserver() {
        self.userRef?.observe(.value) { (snapshot) in
            if let userData = snapshot.value as? [String : Any], let user = DataService.instance.userFromSnapshotValues(userData, withUID: snapshot.key) {
                // Update the cell's UI whenever this user's data changes.
                self.updateUI(user: user, cacheImage: ProfileListVC.imageCache.object(forKey: user.thumbnailURL as NSString))
            }
        }
    }
    
    
    
    
    deinit {
        print("Deallocating an instance of ProfileTableViewCell")
        self.userRef?.removeAllObservers()
    }
}
