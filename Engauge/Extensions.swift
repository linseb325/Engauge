//
//  Extensions.swift
//  Engauge
//
//  Created by Brennan Linse on 3/21/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

extension Date {
    var monthAsString: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM")
        return formatter.string(from: self)
    }
    
    func weekdayAsString(abbreviated: Bool) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate(abbreviated ? "E" : "EEEE")
        return formatter.string(from: self)
    }
    
}

extension Array where Element == Event {
    
    var groupedByDate: [Date : [Event]] {
        return Dictionary(grouping: self, by: { (event) in
            return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: event.startTime) ?? Date(timeIntervalSince1970: 0)
        })
    }
    
}



extension UIViewController {
    
    // If I'm a Navigation Controller, returns my visible View Controller.
    var contentsViewController: UIViewController {
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController ?? self
        } else {
            return self
        }
    }
    
    // If the user taps somewhere outside the keyboard while editing text, dismiss the keyboard.
    func dismissKeyboardWhenTappedOutside() {
        let tapOutsideKeyboard: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapOutsideKeyboard)
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func showErrorAlert(title: String = "Error", message: String) {
        let errorAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(errorAlert, animated: true)
    }
    
    func presentSignInVC(completion: (() -> Void)? = nil) {
        let signInScreen = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SignInVC")
        self.present(signInScreen, animated: true, completion: completion)
    }
    
    func signOutOfFirebaseForDebugging() {
        do {
            try Auth.auth().signOut()
            print("Brennan - signed out successfully")
        } catch {
            print("Brennan - error signing out: \(error.localizedDescription)")
        }
    }
    
}




extension CGPoint {
    
    static func distanceBetween(point p1: CGPoint, andPoint p2: CGPoint) -> CGFloat {
        return sqrt(pow((p2.x - p1.x), 2) + pow((p2.y - p1.y), 2))
    }
    
    static func verticalDistanceBetween(point p1: CGPoint, andPoint p2: CGPoint) -> CGFloat {
        return max(p1.y, p2.y) - min(p1.y, p2.y)
    }
    
}




extension String {
    var isWhitespaceOrEmpty: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}








