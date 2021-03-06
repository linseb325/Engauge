//
//  Extensions.swift
//  Engauge
//
//  Created by Brennan Linse on 3/21/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//
//  PURPOSE: Provide useful methods for working with pre-defined system types.

import Foundation
import UIKit
import SVProgressHUD
import FirebaseAuth

// MARK: Date
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
    
    var lastMoment: Date {
        var oneDay = DateComponents()
        oneDay.day = 1
        return Calendar.current.date(byAdding: oneDay, to: self)!.firstMoment.addingTimeInterval(-1)
    }
    
    var roundingDownToNearestMinute: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        return calendar.date(from: dateComponents)!
    }

}




// MARK: Array<Event>
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
    
    // Assumes the array is sorted from earliest start time to latest start time.
    mutating func insertEvent(_ event: Event) {
        for i in 0..<self.count {
            if event.startTime < self[i].startTime {
                self.insert(event, at: i)
                return
            }
        }
        self.append(event)
    }
    
    mutating func removeEvent(withID eventID: String) {
        if let removeHere = indexOfEvent(withID: eventID) {
            self.remove(at: removeHere)
        }
    }
    
}

// MARK: Array<EngaugeUser>
extension Array where Element == EngaugeUser {
    
    mutating func removeUser(withUID uid: String) {
        if let removeHere = indexOfUser(withUID: uid) {
            self.remove(at: removeHere)
        }
    }
    
    func indexOfUser(withUID uid: String) -> Int? {
        for i in 0..<self.count {
            if self[i].userID == uid {
                return i
            }
        }
        return nil
    }
    
    
    
    
}




// MARK: Array<Transaction>

extension Array where Element == Transaction {
    
    func indexOfTransaction(withID tid: String) -> Int? {
        for i in 0..<self.count {
            if self[i].transactionID == tid {
                return i
            }
        }
        return nil
    }
    
    mutating func removeTransaction(withID tid: String) {
        if let removeHere = indexOfTransaction(withID: tid) {
            self.remove(at: removeHere)
        }
    }
    
}

// MARK: Array<EngaugeNotification>

extension Array where Element == EngaugeNotification {
    
    func indexOfNotification(withID nid: String) -> Int? {
        for i in 0..<self.count {
            if self[i].notificationID == nid {
                return i
            }
        }
        return nil
    }
    
    mutating func removeNotification(withID nid: String) {
        if let removeHere = indexOfNotification(withID: nid) {
            self.remove(at: removeHere)
        }
    }
    
}




// MARK: Dictionary<Date, [Event]>
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




// MARK: UIViewController
extension UIViewController {
    
    /** If I'm a Navigation Controller, returns my visible View Controller. */
    var contentsViewController: UIViewController {
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController ?? self
        } else {
            return self
        }
    }
    
    /** Am I at the root of a tab in a tab bar controller? */
    var isFirstVisibleVCofATab: Bool {
        guard self.tabBarController != nil else {
            return false
        }
        
        if let myNavCon = self.navigationController {
            // I'm in a navcon
            return myNavCon.viewControllers.count == 1 && myNavCon.visibleViewController === self && (self.tabBarController!.viewControllers?.contains(myNavCon) ?? false)
        } else {
            // I'm not in a navcon
            return self.tabBarController!.viewControllers?.contains(self) ?? false
        }
        
    }
    
    /** If the user taps somewhere outside the keyboard while editing text, dismiss the keyboard. */
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
    
}


/** Methods for changing the UI to show something is loading. */
extension UIViewController: Blurrable {
    
    private func setBarButtonsEnabled(_ flag: Bool) {
        // Enable/disable the right bar buttons if necessary.
        if let rightButtons = self.navigationItem.rightBarButtonItems {
            for btn in rightButtons {
                btn.isEnabled = flag
            }
        }
        
        // Enable/disable the left bar buttons if necessary.
        if let leftButtons = self.navigationItem.leftBarButtonItems {
            for btn in leftButtons {
                btn.isEnabled = flag
            }
        }
        
        // Show/hide the back button if necessary.
        self.navigationItem.setHidesBackButton(!flag, animated: true)
    }
    
    /** Enables all navigation bar buttons and shows the back button. */
    func enableBarButtons() {
        setBarButtonsEnabled(true)
    }
    
    /** Disables all navigation bar buttons and hides the back button. */
    func disableBarButtons() {
        setBarButtonsEnabled(false)
    }
    
    
    
    /** Disables bar buttons, blurs the background, and shows the spinner. */
    func showLoadingUI(withBlurStyle style: UIBlurEffectStyle? = nil, withSpinnerText text: String? = nil, withSpinnerFont font: UIFont? = nil) {
        disableBarButtons()
        
        addBlur(withStyle: style ?? .light)
        
        if font != nil {
            SVProgressHUD.setFont(font!)
        }
        
        if text != nil {
            SVProgressHUD.show(withStatus: text!)
        } else {
            SVProgressHUD.show()
        }
    }
    
    /** Dismisses the spinner, removes the blur, and enables bar buttons. */
    func hideLoadingUI(completion: (() -> Void)? = nil) {
        SVProgressHUD.dismiss()
        removeBlurIfNecessary()
        enableBarButtons()
        completion?()
    }
    
}


/** Provides default implementations for Blurrable methods if the adopting instance is a UIViewController. */
extension Blurrable where Self: UIViewController {
    
    /** Adds a UIEffectView with a blur effect as an immediate subview of the main view. */
    func addBlur(withStyle blurStyle: UIBlurEffectStyle) {
        let blurEffect = UIBlurEffect(style: blurStyle)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = self.view.frame
        self.view.addSubview(blurView)
    }
    
    /** Removes any immediate subviews of the main view if they are UIVisualEffectViews whose effects are blur effects. */
    func removeBlurIfNecessary() {
        for subview in self.view.subviews {
            if let blurView = subview as? UIVisualEffectView, blurView.effect is UIBlurEffect {
                blurView.removeFromSuperview()
            }
        }
    }
    
}





// MARK: CGPoint
extension CGPoint {
    
    static func distanceBetween(point p1: CGPoint, andPoint p2: CGPoint) -> CGFloat {
        return sqrt(pow((p2.x - p1.x), 2) + pow((p2.y - p1.y), 2))
    }
    
    static func verticalDistanceBetween(point p1: CGPoint, andPoint p2: CGPoint) -> CGFloat {
        return max(p1.y, p2.y) - min(p1.y, p2.y)
    }
    
}




// MARK: String
extension String {
    var isWhitespaceOrEmpty: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /** A string passed to ref.child(...) must be non-empty and may not contain certain illegal characters. */
    var isLegalFirebaseChild: Bool {
        guard !self.isEmpty else {
            return false
        }
        
        for currChar in self {
            if String.illegalFirebaseChildCharacters.contains(currChar) {
                return false
            }
        }
        
        return true
    }
    
    static var illegalFirebaseChildCharacters: [Character] = [ ".", "#", "$", "[", "]" ]
}



// MARK: UIWindow
extension UIWindow {
    
    func switchRootViewController(_ viewController: UIViewController,  animated: Bool = true, duration: TimeInterval = 0.5, options: UIViewAnimationOptions = .transitionFlipFromRight, completion: (() -> Void)? = nil) {
        guard animated else {
            rootViewController = viewController
            return
        }
        
        UIView.transition(with: self, duration: duration, options: options, animations: {
            let oldState = UIView.areAnimationsEnabled
            UIView.setAnimationsEnabled(false)
            self.rootViewController = viewController
            UIView.setAnimationsEnabled(oldState)
        }) { _ in
            completion?()
        }
    }
}


