//
//  AdjustableButton.swift
//  Engauge
//
//  Created by Brennan Linse on 5/7/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit

class AdjustableButton: UIButton {
    
    // MARK: Rounded Edges
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            if !isOval {
                layer.cornerRadius = cornerRadius
                // layer.masksToBounds = cornerRadius > 0
            }
        }
    }
    
    @IBInspectable var isOval: Bool = false {
        didSet {
            if isOval {
                layer.cornerRadius = min(layer.frame.height, layer.frame.width) / 2
                // layer.masksToBounds = layer.cornerRadius > 0
            } else {
                layer.cornerRadius = self.cornerRadius
            }
        }
    }
    
    
    
    
    // MARK: Shadows
    
    @IBInspectable var shadowRadius: CGFloat = 0 {
        didSet {
            layer.shadowRadius = shadowRadius
        }
    }
    
    @IBInspectable var shadowColor: UIColor? {
        didSet {
            layer.shadowColor = shadowColor?.cgColor
        }
    }
    
    @IBInspectable var shadowOpacity: Float = 0.0 {
        didSet {
            layer.shadowOpacity = shadowOpacity
        }
    }
    
    @IBInspectable var shadowOffset: CGSize = CGSize(width: 0, height: 3) {
        didSet {
            layer.shadowOffset = shadowOffset
        }
    }
    
    
    
    
    // MARK: Borders
    
    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
        
    }
    
}
