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
    
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // When the orientation changes, we need to change the margins at the very top and bottom of the screen.
        NotificationCenter.default.addObserver(self, selector: #selector(handleOrientationDidChange), name: Notification.Name.UIDeviceOrientationDidChange, object: nil)
        
        self.view.layoutIfNeeded()
        
        setTopSpaceConstraint()
        
        
        updateUIForCurrentEvent()
        
        // Configuring UI based on the current user's role
        let authListenerHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let currUser = user {
                
                DataService.instance.getRoleForUser(withUID: currUser.uid) { (roleNum) in
                    guard let roleNum = roleNum else {
                        // TESTME: Couldn't retrieve the user's role.
                        self.showErrorAlert(message: "Database error: Couldn't verify your role.", dismissHandler: { (okAction) in
                            self.navigationController?.popViewController(animated: true)
                        })
                        return
                    }
                    
                    switch roleNum {
                        
                    case UserRole.student.toInt:
                        // Set up UI for favoriting an event.
                        DataService.instance.isEventFavoritedByUser(withUID: currUser.uid, eventID: self.event.eventID) { (isFavorite) in
                            let favoriteButton = FavoriteBarButtonItem(isFilled: isFavorite, target: self, action: #selector(self.handleFavoriteButtonTapped))
                            self.navigationItem.rightBarButtonItem = favoriteButton
                        }
                        // Students can't see the event's transactions.
                        self.hideTransactionsUI()
                        self.resizeContainerViewToFitContent()
                        
                    case UserRole.scheduler.toInt:
                        DataService.instance.wasEventScheduledByUser(withUID: currUser.uid, eventID: self.event.eventID) { (isMyEvent) in
                            if isMyEvent {
                                // Schedulers can edit and delete events they scheduled.
                                self.setUpEditAndDeleteUI()
                                // Schedulers can view transactions for events they scheduled.
                                DataService.instance.getTransactions(withIDs: self.event.associatedTransactionIDs ?? [String]()) { (transactionsRetrieved) in
                                    self.transactions = transactionsRetrieved
                                    self.transactionsTableView.reloadData()
                                }
                            } else {
                                // Schedulers can't view transactions for an event unless they scheduled that event.
                                self.hideTransactionsUI()
                                self.resizeContainerViewToFitContent()
                            }
                        }
                        
                    case UserRole.admin.toInt:
                        // Admins can edit and delete any event.
                        self.setUpEditAndDeleteUI()
                        // Admins can view transactions for any event.
                        DataService.instance.getTransactions(withIDs: self.event.associatedTransactionIDs ?? [String]()) { (transactionsRetrieved) in
                            self.transactions = transactionsRetrieved
                            self.transactionsTableView.reloadData()
                        }
                    default:
                        break
                    }
                }
            } else {
                // Nobody is signed in. Probably shouldn't happen at this point...
                self.presentSignInVC()
            }
        }
        Auth.auth().removeStateDidChangeListener(authListenerHandle)
        
    }
    
    override func viewDidLayoutSubviews() {
        print("Did layout subviews")
    }
    
    override func viewWillLayoutSubviews() {
        print("Will layout subviews")
    }
    
    
    
    // MARK: Table View methods
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.transactionsTableView.dequeueReusableCell(withIdentifier: "TransactionTableViewCell") as? TransactionTableViewCell
        cell?.configureCell(transaction: transactions[indexPath.row])
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.transactions.count
    }
    
    
    
    
    // MARK: Bar button item actions
    
    @objc func handleFavoriteButtonTapped() {
        if let favoriteButton = self.navigationItem.rightBarButtonItem as? FavoriteBarButtonItem {
            favoriteButton.toggleImage()
            DataService.instance.setFavorite(favoriteButton.isFilled, eventWithID: self.event.eventID, forUserWithUID: Auth.auth().currentUser?.uid ?? "no-current-user") { (errMsg) in
                guard errMsg == nil else {
                    favoriteButton.toggleImage()
                    self.showErrorAlert(message: errMsg!)
                    return
                }
            }
        }
    }
    
    @objc func handleDeleteButtonTapped() {
        
        let areYouSureAlert = UIAlertController(title: "Delete event?", message: "Are you sure you'd like to delete this event? You can't undo this operation!", preferredStyle: .alert)
        areYouSureAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        areYouSureAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (deleteAction) in
            
            // Delete the event images from Storage if necessary.
            if self.event.imageURL != nil, self.event.thumbnailURL != nil {
                StorageService.instance.deleteImage(atURL: self.event.imageURL!)
                StorageService.instance.deleteImage(atURL: self.event.thumbnailURL!)
            }
            
            // Delete the event data from the database.
            DataService.instance.deleteEvent(self.event) { (errorMessage) in
                guard errorMessage == nil else {
                    self.showErrorAlert(message: errorMessage!)
                    return
                }
                
                // Deletion was successful.
                if let navcon = self.navigationController {
                    // Should always be true because this VC should always be presented with a show segue
                    print("Brennan - EventDetailsVC is in a navigation controller. Dismissing it.")
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
    
    @objc func handleEditButtonTapped() {
        // Launch the Edit Event Screen.
        performSegue(withIdentifier: "toEditEventTVC", sender: self.event)
    }
    
    
    
    
    // MARK: Adjusting the UI
    
    private func hideDescriptionUI() {
        self.descriptionStackView.frame.size.height = 0
        self.descriptionStackView.isHidden = true
    }
    
    private func hideTransactionsUI() {
        self.transactionsStackView.frame.size.height = 0
        self.transactionsStackView.isHidden = true
    }
    
    private func showDescriptionUI() {
        self.descriptionStackView.isHidden = false
        self.descriptionStackView.sizeToFit()
    }
    
    private func showTransactionsUI() {
        self.transactionsStackView.isHidden = false
        self.transactionsStackView.sizeToFit()
    }
    
    func resizeContainerViewToFitContent() {
        
        self.view.layoutIfNeeded()
        
        let newHeight = CGPoint.verticalDistanceBetween(point: self.containerView.bounds.origin, andPoint: CGPoint(x: 0, y: contentStackView.frame.origin.y + contentStackView.frame.height + imageViewTopSpaceConstraint.constant))
        self.containerViewHeightConstraint.constant = newHeight
        
        self.scrollView.sizeToFit()
        self.view.layoutIfNeeded()
    }
    
    @objc func setTopSpaceConstraint() {
        imageViewTopSpaceConstraint.constant = (containerView.bounds.width - imageView.frame.width) / 2
    }
    
    @objc func handleOrientationDidChange() {
        setTopSpaceConstraint()
        resizeContainerViewToFitContent()
    }
    
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
    
    private func updateUIForCurrentEvent() {
        // Download the event image if there is one.
        if let eventImageURL = event.imageURL {
            Storage.storage().reference(forURL: eventImageURL).getData(maxSize: 2 * 1024 * 1024) { (data, error) in
                if error == nil, data != nil {
                    let eventImage = UIImage(data: data!)
                    self.imageView.image = eventImage
                }
            }
        }
        
        // Retrieve the scheduler's name from the database and display it.
        DataService.instance.getNameForUser(withUID: event.schedulerUID) { (schedulerName) in
            self.schedulerNameLabel.text = schedulerName ?? "[Not available]"
            self.resizeContainerViewToFitContent()
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
            self.descriptionBodyLabel.numberOfLines = 50
            showDescriptionUI()
        } else {
            hideDescriptionUI()
            // Matching call to resizeContainerViewToFitContent() is below.
        }
        
        resizeContainerViewToFitContent()
    }
    
    
    
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toEditEventTVC":
            if let destVC = segue.destination.contentsViewController as? EditEventTVC {
                destVC.event = self.event
            }
        default:
            break
        }
    }
    
    @IBAction func unwindFromEditEventTVC(sender: UIStoryboardSegue) {
        if let sourceVC = sender.source as? EditEventTVC, let editedEvent = sourceVC.editedEvent {
            self.event = editedEvent
            updateUIForCurrentEvent()
        }
    }

    
    
    
    
    
    
    
    
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
}
