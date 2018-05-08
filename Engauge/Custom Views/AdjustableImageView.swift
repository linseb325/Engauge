//
//  AdjustableImageView.swift
//  Engauge
//
//  Created by Brennan Linse on 5/7/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit

@IBDesignable class AdjustableImageView: UIImageView {
    
    // MARK: Rounded Edges
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    
    // Must set a border width to use this
    @IBInspectable var isOval: Bool = false {
        didSet {
            if isOval {
                self.cornerRadius = min(layer.frame.height, layer.frame.width) / 2
            } else {
                layer.cornerRadius = self.cornerRadius
            }
            layer.masksToBounds = cornerRadius > 0
        }
    }
    
}
