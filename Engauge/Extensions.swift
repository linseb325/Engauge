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
    
    var firstMoment: Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day], from: self))!
    }
    
    var roundingDownToNearestMinute: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        return calendar.date(from: dateComponents)!
    }

}




extension Array where Element == Event {
    
    var groupedByDate: [Date : [Event]] {
        return Dictionary(grouping: self, by: { (event) in
            return event.startTime.firstMoment
        })
    }
    
    func indexOfEvent(withID eventID: String) -> Int? {
        for i in 0..<self.count {
            if self[i].eventID == eventID {
                return i
            }
        }
        return nil
    }
    
    mutating func insertEvent(_ event: Event) {
        for i in 0..<self.count {
            if event.startTime < self[i].startTime {
                self.insert(event, at: i)
                return
            }
        }
        self.append(event)
    }
    
}




extension Dictionary where Key == Date, Value == [Event] {
    
    mutating func insertEvent(_ event: Event) {
        let eventStartZeroed = event.startTime.firstMoment
        if self.keys.contains(eventStartZeroed) {
            self[eventStartZeroed]?.insertEvent(event)
        } else {
            self[eventStartZeroed] = [event]
        }
    }
    
    mutating func removeEvent(withID eventID: String) -> Event? {
        for (dateKey, eventsOnDate) in self {
            if let eventPos = eventsOnDate.indexOfEvent(withID: eventID) {
                let removedEvent = self[dateKey]?.remove(at: eventPos)
                // If we just removed the last event for a certain date, remove that date key from the dictionary.
                if (self[dateKey]?.isEmpty ?? false) {
                    self[dateKey] = nil
                }
                return removedEvent
            }
        }
        return nil
    }
    
    func containsEvent(withID eventID: String) -> Bool {
        for (_, value) in self {
            if value.contains(where: { $0.eventID == eventID }) {
                return true
            }
        }
        return false
    }
    
    func indexPathForEvent(withID eventID: String) -> IndexPath? {
        let dateKeysInOrder = self.keys.sorted()
        for sectionNum in 0..<dateKeysInOrder.count {
            if let rowNum = self[dateKeysInOrder[sectionNum]]?.indexOfEvent(withID: eventID) {
                return IndexPath(row: rowNum, section: sectionNum)
            }
        }
        return nil
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
    
    func showErrorAlert(title: String = "Error", message: String, dismissHandler: ((UIAlertAction) -> Void)? = nil) {
        let errorAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: dismissHandler))
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








