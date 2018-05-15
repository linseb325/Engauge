//
//  EventDetailsVC.swift
//  Engauge
//
//  Created by Brennan Linse on 3/21/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseAuth
import FirebaseDatabase
import EventKit

class EventDetailsVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Outlets
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var schedulerNameLabel: UILabel!
    @IBOutlet weak var descriptionStackView: UIStackView!
    @IBOutlet weak var descriptionHeaderLabel: UILabel!
    @IBOutlet weak var descriptionBodyLabel: UILabel!
    @IBOutlet weak var transactionsStackView: UIStackView!
    @IBOutlet weak var transactionsHeaderLabel: UILabel!
    @IBOutlet weak var transactionsTableView: UITableView! {
        didSet {
            transactionsTableView.dataSource = self
            transactionsTableView.delegate = self
        }
    }
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var imageViewTopSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentStackView: UIStackView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    
    
    
    // MARK: Properties
    var event: Event!
    var transactions = [Transaction]()
    
    private var eventDataRef: DatabaseReference?
    private var eventDataChangedHandle: DatabaseHandle?
    
    private var eventStore = EKEventStore()
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.layoutIfNeeded()
        
        self.eventDataRef = DataService.instance.REF_EVENTS.child(event.eventID)
        removeDatabaseObserverIfNecessary()
        attachDatabaseObserver()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let selectedIndexPath = self.transactionsTableView.indexPathForSelectedRow {
            transactionsTableView.deselectRow(at: selectedIndexPath, animated: true)
        }
    }
    
    
    
    
    // MARK: Updating the UI
    
    /** Sets the height of the stack view holding the description UI to 0 and sets isHidden to true. */
    private func hideDescriptionUI() {
        self.descriptionStackView.frame.size.height = 0
        self.descriptionStackView.isHidden = true
    }
    
    /** Resizes the stack view holding the description UI to fit its contents and sets isHidden to false. */
    private func showDescriptionUI() {
        self.descriptionStackView.isHidden = false
        self.descriptionStackView.sizeToFit()
    }
    
    /** Sets the height of the stack view holding the transaction UI to 0 and sets isHidden to true. */
    private func hideTransactionsUI() {
        self.transactionsStackView.frame.size.height = 0
        self.transactionsStackView.isHidden = true
    }
    
    /** Resizes the stack view holding the transaction UI to fit its contents and sets isHidden to false. */
    private func showTransactionsUI() {
        self.transactionsStackView.isHidden = false
        self.transactionsStackView.sizeToFit()
    }
    
    /**
     - Changes the container view's height constant to contentStackView's height + 2(top margin).
     - Sizes the scroll view to fit its content.
     - Lays out the main view/subviews if needed.
     */
    func resizeContainerAndScrollViewsToFitContent() {
        self.view.layoutIfNeeded()
        
        let newHeight = CGPoint.verticalDistanceBetween(point: self.containerView.bounds.origin, andPoint: CGPoint(x: 0, y: contentStackView.frame.origin.y + contentStackView.frame.height + imageViewTopSpaceConstraint.constant))
        self.containerViewHeightConstraint.constant = newHeight
        
        self.scrollView.sizeToFit()
        self.view.layoutIfNeeded()
    }
    
    /** Sets the right bar buttons to Edit (if not too late) and Delete. */
    private func setUpEditAndDeleteUI() {
        var barButtons = [UIBarButtonItem]()
        let deleteButton = UIBarButtonItem(barButtonSystemItem: .trash , target: self, action: #selector(self.handleDeleteButtonTapped))
        deleteButton.tintColor = UIColor.red
        barButtons.append(deleteButton)
        
        // Events can only be edited before they begin.
        if self.event.startTime > Date() {
            // The event hasn't started yet, so it's still editable.
            let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(self.handleEditButtonTapped))
            barButtons.insert(contentsOf: [editButton, space], at: 0)
        }
        
        self.navigationItem.setRightBarButtonItems(barButtons, animated: true)
    }
    
    /** Updates the image, labels, description UI (including show/hide), and scheduler's name. Requires self.event to be set. */
    private func updateUIForCurrentEvent() {
        // Download the event image if there is one.
        if let eventImageURL = event.imageURL {
            StorageService.instance.getImageForEvent(withID: event.eventID, thumbnail: false) { (eventImage) in
                if eventImage != nil {
                    self.imageView.image = eventImage
                }
            }
        }
        
        // Retrieve the scheduler's name from the database and display it.
        DataService.instance.getNameForUser(withUID: event.schedulerUID) { (schedulerName) in
            self.schedulerNameLabel.text = schedulerName ?? "[Not available]"
            self.resizeContainerAndScrollViewsToFitContent()
        }
        
        // Display the event's name, date, time, and location.
        self.nameLabel.text = event.name
        
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMMM d, yyyy")
        self.dateLabel.text = formatter.string(from: event.startTime)
        
        let eventIsOneDay = Calendar.current.isDate(event.startTime, inSameDayAs: event.endTime)
        formatter.setLocalizedDateFormatFromTemplate(eventIsOneDay ? "h:mm a" : "h:mm a E")
        let startTime = formatter.string(from: event.startTime)
        let endTime = formatter.string(from: event.endTime)
        self.timeLabel.text = "\(startTime) - \(endTime)"
        
        self.locationLabel.text = event.location
        
        // Display the event's description if there is one.
        if event.description != nil {
            self.descriptionBodyLabel.text = event.description
            self.descriptionBodyLabel.numberOfLines = 0
            showDescriptionUI()
        } else {
            hideDescriptionUI()
            // Matching call to resizeContainerViewToFitContent() is below.
        }
        
        resizeContainerAndScrollViewsToFitContent()
    }
    
    /**
     Configures UI based on the current user's role.
     - This affects:
     - The right bar buttons (favorite button, edit/delete buttons, or none)
     - The transactions table view (shows/hides it and populates it with data)
     */
    private func configureAdaptableUI() {
        
        guard let currUserUID = Auth.auth().currentUser?.uid else {
            // TODO
            return
        }
        
        // Retrieve my role.
        DataService.instance.getRoleForUser(withUID: currUserUID) { (roleNum) in
            guard let currUserRoleNum = roleNum else {
                // TESTME: Couldn't retrieve the user's role.
                self.showErrorAlert(message: "Database error: Couldn't verify your role.", dismissHandler: { (okAction) in
                    self.navigationController?.popViewController(animated: true)
                })
                return
            }
            
            // What is my role?
            switch currUserRoleNum {
                
            case UserRole.student.toInt:
                // I'm a student.
                // Set up UI for favoriting an event.
                DataService.instance.isEventFavoritedByUser(withUID: currUserUID, eventID: self.event.eventID) { (isFavorite) in
                    let favoriteButton = FavoriteBarButtonItem(isFilled: isFavorite, target: self, action: #selector(self.handleFavoriteButtonTapped))
                    var buttons: [UIBarButtonItem] = [favoriteButton]
                    // Set up UI for adding the event to your calendar if the event hasn't started yet.
                    if self.event.startTime > Date() {
                        let space = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
                        let calendarAddButton = UIBarButtonItem(image: UIImage(named: "calendar-add"), style: .plain, target: self, action: #selector(self.handleCalendarAddButtonTapped))
                        buttons += [space, calendarAddButton]
                    }

                    self.navigationItem.setRightBarButtonItems(nil, animated: true)     // Clears out any existing bar buttons.
                    
                    self.navigationItem.setRightBarButtonItems(buttons, animated: true)
                }
                // Students can't see the event's transactions.
                self.hideTransactionsUI()
                self.resizeContainerAndScrollViewsToFitContent()
                
            case UserRole.scheduler.toInt:
                // I'm a scheduler.
                DataService.instance.wasEventScheduledByUser(withUID: currUserUID, eventID: self.event.eventID) { (isMyEvent) in
                    if isMyEvent {
                        // Schedulers can edit and delete events they scheduled.
                        self.setUpEditAndDeleteUI()
                        // Schedulers can view transactions for events they scheduled.
                        DataService.instance.getTransactionsForEvent(withID: self.event.eventID){ (retrievedTransactions) in
                            self.transactions = retrievedTransactions
                            self.showTransactionsUI()
                            self.resizeContainerAndScrollViewsToFitContent()
                            self.transactionsTableView.reloadData()
                        }
                    } else {
                        // Schedulers can't view transactions for an event unless they scheduled that event.
                        self.navigationItem.setRightBarButtonItems(nil, animated: true)     // Removes "Edit" and "Delete" if they're visible.
                        self.hideTransactionsUI()
                        self.resizeContainerAndScrollViewsToFitContent()
                    }
                }
                
            case UserRole.admin.toInt:
                // I'm an Admin.
                // Admins can edit and delete any event.
                self.setUpEditAndDeleteUI()
                // Admins can view transactions for any event.
                self.showTransactionsUI()
                self.resizeContainerAndScrollViewsToFitContent()
                DataService.instance.getTransactionsForEvent(withID: self.event.eventID) { (retrievedTransactions) in
                    self.transactions = retrievedTransactions
                    self.transactionsTableView.reloadData()
                }
            default:
                break
            }
        }
        
    }
    
    
    
    
    // MARK: Table View methods
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("TransactionTableViewCell", owner: self, options: nil)?.first as? TransactionTableViewCell
        cell?.configureCell(transaction: transactions[indexPath.row])
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.transactions.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !transactionsStackView.isHidden, transactions.count > indexPath.row {
            performSegue(withIdentifier: "toTransactionDetailsVC", sender: transactions[indexPath.row])
        }
    }
    
    
    
    
    // MARK: Bar button item actions
    
    @objc private func handleFavoriteButtonTapped() {
        if let favoriteButton = self.navigationItem.rightBarButtonItem as? FavoriteBarButtonItem {
            favoriteButton.toggle()
            DataService.instance.setFavorite(favoriteButton.isFilled, eventWithID: self.event.eventID, forUserWithUID: Auth.auth().currentUser?.uid ?? "no-current-user") { (errMsg) in
                guard errMsg == nil else {
                    favoriteButton.toggle()
                    self.showErrorAlert(message: errMsg!)
                    return
                }
            }
        }
    }
    
    @objc private func handleDeleteButtonTapped() {
        
        let areYouSureAlert = UIAlertController(title: "Delete event?", message: "Are you sure you'd like to delete this event? You can't undo this operation!", preferredStyle: .alert)
        areYouSureAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        areYouSureAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (deleteAction) in
            
            // Delete the event data from the database.
            DataService.instance.deleteEvent(self.event) { (errorMessage) in
                guard errorMessage == nil else {
                    self.showErrorAlert(message: errorMessage!)
                    return
                }
                
                // Deletion was successful.
                if let navcon = self.navigationController {
                    // Should always be true because this VC should always be presented with a show segue
                    print("Brennan - EventDetailsVC is in a navigation controller as expected. Dismissing it.")
                    navcon.popViewController(animated: true)
                } else {
                    // Should never be true. See above
                    print("Brennan - EventDetailsVC is not in a navigation controller for some reason. This is fishy.")
                    self.navigationItem.rightBarButtonItems = nil
                    self.view.layoutIfNeeded()
                }
            }
        }))
        present(areYouSureAlert, animated: true)
    }
    
    @objc private func handleEditButtonTapped() {
        // Launch the Edit Event Screen.
        performSegue(withIdentifier: "toEditEventTVC", sender: self.event)
    }
    
    @objc private func handleCalendarAddButtonTapped() {
        let areYouSureAlert = UIAlertController(title: "Add to calendar?", message: "Would you like to add this event to your iOS calendar?", preferredStyle: .alert)
        areYouSureAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        areYouSureAlert.addAction(UIAlertAction(title: "Add", style: .default, handler: { (addAction) in
            
            self.eventStore.requestAccess(to: .event) { (accessGranted, error) in
                guard accessGranted else {
                    self.showErrorAlert(message: "Access to calendars is not granted. Please configure this in system settings.")
                    return
                }
                
                let newEvent = EKEvent(eventStore: self.eventStore)
                newEvent.title = self.event.name
                newEvent.location = self.event.location
                newEvent.startDate = self.event.startTime
                newEvent.endDate = self.event.endTime
                newEvent.notes = self.event.description
                
                guard let defaultCalendar = self.eventStore.defaultCalendarForNewEvents else {
                    self.showErrorAlert(message: "Couldn't save the event to your calendar. Please select a default calendar in your calendar settings.")
                    return
                }
                
                newEvent.calendar = defaultCalendar
                
                do {
                    try self.eventStore.save(newEvent, span: .thisEvent, commit: true)
                    self.showSuccessAlertForEventCreated()
                } catch let saveEventError {
                    self.showErrorAlert(message: "There was an issue adding this event to your calendar.")
                    print("Error saving event to calendar: \(saveEventError.localizedDescription)")
                }
            }
        }))
        present(areYouSureAlert, animated: true)
    }
    
    private func showSuccessAlertForEventCreated() {
        let successAlert = UIAlertController(title: "Success!", message: "Saved the event to your calendar.", preferredStyle: .alert)
        successAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(successAlert, animated: true)
    }
    
    
    
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toEditEventTVC":
            if let destVC = segue.destination.contentsViewController as? EditEventTVC {
                destVC.event = self.event
            }
        case "toTransactionDetailsVC":
            if let transactionScreen = segue.destination.contentsViewController as? TransactionDetailsVC, let pickedTransaction = sender as? Transaction {
                transactionScreen.transaction = pickedTransaction
            }
        default:
            break
        }
    }
    
    
    
    
    // MARK: Database Observer
    
    private func attachDatabaseObserver() {
        self.eventDataChangedHandle = self.eventDataRef?.observe(.value) { [weak self] (snapshot) in
            if let eventData = snapshot.value as? [String : Any], let updatedEvent = DataService.instance.eventFromSnapshotValues(eventData, withID: snapshot.key) {
                self?.event = updatedEvent
                self?.updateUIForCurrentEvent()
                self?.configureAdaptableUI()
            }
        }
    }
    
    private func removeDatabaseObserverIfNecessary() {
        if eventDataChangedHandle != nil {
            eventDataRef?.removeObserver(withHandle: eventDataChangedHandle!)
            eventDataChangedHandle = nil
        }
    }
    
    
    
    
    // MARK: Deinitializer
    
    deinit {
        print("Deallocating an instance of EventDetailsVC")
        removeDatabaseObserverIfNecessary()
    }
    
}
