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
    
    private var _isFilled: Bool
    
    var isFilled: Bool {
        return _isFilled
    }
    
    static let filledStarImage = UIImage(named: "filled-star")
    static let emptyStarImage = UIImage(named: "empty-star")
    
    
    
    // MARK: Initializers
    
    init(isFilled: Bool, target: AnyObject?, action: Selector?) {
        _isFilled = isFilled
        super.init()
        self.setImage(filled: isFilled)
        self.target = target
        self.action = action
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: Public API
    func toggle() {
        _isFilled = !_isFilled
        self.setImage(filled: _isFilled)
    }
    
    
    
    // MARK: Private API
    private func setImage(filled: Bool) {
        self.image = filled ? FavoriteBarButtonItem.filledStarImage : FavoriteBarButtonItem.emptyStarImage
    }
    
}

