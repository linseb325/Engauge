//
//  NotificationListTVC.swift
//  Engauge
//
//  Created by Brennan Linse on 5/1/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//
//  PURPOSE: Show an Admin any pending requests for Scheduler status at his/her school.

import UIKit
import FirebaseAuth
import FirebaseDatabase

class NotificationListTVC: UITableViewController {
    
    // MARK: Outlets
    
    
    
    
    // MARK: Properties
    
    private var notifications = [EngaugeNotification]()
    
    private var userNotificationsRef: DatabaseReference?
    private var notificationAddedHandle: DatabaseHandle?
    private var notificationRemovedHandle: DatabaseHandle?
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let currUser = Auth.auth().currentUser else {
            // TODO: No user is signed in!
            return
        }
        
        self.attachNotificationObservers(adminUID: currUser.uid)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
    }
    
    
    
    
    // MARK: Database Observers
    
    /** Removes old observer handles. Sets the DB reference. Sets up the observers for when a notification is added or removed. */
    private func attachNotificationObservers(adminUID: String) {
        removeNotificationObserverHandlesIfNecessary()
        
        self.userNotificationsRef = DataService.instance.REF_USER_NOTIFICATIONS.child(adminUID)
        
        self.notificationAddedHandle = userNotificationsRef?.observe(.childAdded) { [weak self] (snapshot) in
            DataService.instance.getNotification(withID: snapshot.key) { (newNotif) in
                if newNotif != nil {
                    self?.notifications.append(newNotif!)
                    self?.notifications.sort { $0.timestamp > $1.timestamp }
                    self?.tableView.reloadData()
                }
            }
        }
        
        self.notificationRemovedHandle = userNotificationsRef?.observe(.childRemoved) { [weak self] (snapshot) in
            let oldNotifID = snapshot.key
            if let removeHere = self?.notifications.index(where: { $0.notificationID == oldNotifID }) {
                self?.notifications.remove(at: removeHere)
            }
            self?.tableView.reloadData()
        }
    }
    
    private func removeNotificationObserverHandlesIfNecessary() {
        if notificationAddedHandle != nil {
            userNotificationsRef?.removeObserver(withHandle: notificationAddedHandle!)
            notificationAddedHandle = nil
        }
        if notificationRemovedHandle != nil {
            userNotificationsRef?.removeObserver(withHandle: notificationRemovedHandle!)
            notificationRemovedHandle = nil
        }
    }
    
    
    
    
    // MARK: Table View Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.notifications.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("NotificationTableViewCell", owner: self, options: nil)?.first as? NotificationTableViewCell
        cell?.configureCell(notification: notifications[indexPath.row], forVCWithTypeName: "NotificationListTVC")
        
        return cell ?? UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "toRoleRequestDetailsVC", sender: notifications[indexPath.row])
    }
    
    
    
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
            
        case "toRoleRequestDetailsVC":
            if let roleReqScreen = segue.destination as? RoleRequestDetailsVC, let pickedNotif = sender as? EngaugeNotification {
                roleReqScreen.notification = pickedNotif
            }
        default:
            break
        }
    }
    
    
    
    
    // MARK: Deinitializer
    
    deinit {
        print("Deallocating an instance of NotificationListTVC")
        removeNotificationObserverHandlesIfNecessary()
    }
    
}
