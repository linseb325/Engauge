//
//  FavoriteBarButtonItem.swift
//  Engauge
//
//  Created by Brennan Linse on 3/23/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit

class FavoriteBarButtonItem: UIBarButtonItem {
    
    // MARK: Properties
    var isFilled: Bool
    let filledStarImage = UIImage(named: "filled-star")
    let emptyStarImage = UIImage(named: "empty-star")
    
    
    
    
    // MARK: Initializers
    
    init(isFilled: Bool, target: AnyObject?, action: Selector?) {
        self.isFilled = isFilled
        super.init()
        self.setImage(filled: isFilled)
        self.target = target
        self.action = action
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: Public API
    func toggleImage() {
        self.isFilled = !isFilled
        self.setImage(filled: isFilled)
    }
    
    
    
    // MARK: Private API
    private func setImage(filled: Bool) {
        self.image = filled ? filledStarImage : emptyStarImage
    }
    
}

