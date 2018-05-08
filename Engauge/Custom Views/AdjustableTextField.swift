//
//  AdjustableTextField.swift
//  Engauge
//
//  Created by Brennan Linse on 5/7/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit

@IBDesignable class AdjustableTextField: UITextField {
    
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
    
    // MARK: Text Insets
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 10, dy: 5)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 10, dy: 5)
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
    
    
    
    
    // MARK: Placeholder Color
    
    @IBInspectable var placeholderColor: UIColor? {
        didSet {
            let rawString = attributedPlaceholder?.string != nil ? attributedPlaceholder!.string : ""
            let attributedStr = NSAttributedString(string: rawString, attributes: [NSAttributedStringKey.foregroundColor: placeholderColor!])
            attributedPlaceholder = attributedStr
        }
    }

    
}
