//
//  Constants.swift
//  Engauge
//
//  Created by Brennan Linse on 3/3/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    var contentsViewController: UIViewController {
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController ?? self
        } else {
            return self
        }
    }
    
    func dismissKeyboardWhenTappedOutside() {
        // If the user taps somewhere outside the keyboard while editing text, dismiss the keyboard.
        let tapOutsideKeyboard: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapOutsideKeyboard)
    }
    
    @objc private func dismissKeyboard() {
        self.view.endEditing(true)
    }
}
