//
//  FilterEventsTVC.swift
//  Engauge
//
//  Created by Brennan Linse on 3/13/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit
import FirebaseAuth

class FilterEventsTVC: UITableViewController {
    
    // MARK: Outlets
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    @IBOutlet weak var dateSwitch: UISwitch!
    @IBOutlet weak var favoritesSwitch: UISwitch!
    
    
    
    // MARK: Properties
    
    var filtersCreated: [EventFilterFactory.EventFilter]?
    
    static let formatter: DateFormatter = {
        let form = DateFormatter()
        form.timeStyle = .none
        form.dateStyle = .medium
        return form
    }()
    
    var startDate: Date? {
        didSet {
            if let newDate = startDate {
                startDateLabel.text = FilterEventsTVC.formatter.string(from: newDate)
            } else {
                startDateLabel.text = "-"
            }
        }
    }
    
    var endDate: Date? {
        didSet {
            if let newDate = endDate {
                endDateLabel.text = FilterEventsTVC.formatter.string(from: newDate)
            } else {
                endDateLabel.text = "-"
            }
        }
    }
    
    private var dateDisplaysVisible = false
    private var startDatePickerVisible = false
    private var endDatePickerVisible = false
    
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // The user can only filter by favorites if he/she is a Student.
        if let currUser = Auth.auth().currentUser {
            DataService.instance.getRoleForUser(withUID: currUser.uid, completion: { (role) in
                if let roleNum = role {
                    if roleNum != UserRole.student.toInt {
                        // User is not a student. Can't filter by favorites.
                        self.favoritesSwitch.isEnabled = false
                    } else {
                        // User is a student. Can filter by favorites.
                        self.favoritesSwitch.isEnabled = true
                    }
                } else {
                    // Couldn't verify user role. Don't allow to filter by favorites.
                    self.favoritesSwitch.isEnabled = false
                }
            })
        } else {
            // TODO: There is no user logged in! (Shouldn't happen...)
            self.favoritesSwitch.isEnabled = false
        }
    }
    
    
    
    // MARK: Date Pickers
    
    @IBAction func startDatePickerChanged(_ sender: UIDatePicker) {
        startDate = sender.date
    }
    
    @IBAction func endDatePickerChanged(_ sender: UIDatePicker) {
        endDate = sender.date
    }
    
    
    
    // MARK: Switches
    
    @IBAction func dateSwitchChanged(_ sender: UISwitch) {
        if dateDisplaysVisible {
            // Switch was turned OFF
            dateDisplaysVisible = false
            startDatePickerVisible = false
            endDatePickerVisible = false
            startDate = nil
            endDate = nil
        } else {
            // Switch was turned ON
            dateDisplaysVisible = true
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    
    
    // MARK: Table View methods
    
    // Tapped a cell
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            // Tapped the "filter by date" section
            switch indexPath.row {
            case 1:
                // Tapped the start date display
                startDatePickerVisible = !startDatePickerVisible
                startDate = startDatePicker.date
            case 3:
                // Tapped the end date display
                endDatePickerVisible = !endDatePickerVisible
                endDate = endDatePicker.date
            default:
                return
            }
            
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    // Row heights
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            switch indexPath.row {
            case 1, 3:
                return dateDisplaysVisible ? 44.0 : 0.0
            case 2:
                return startDatePickerVisible ? 200.0 : 0.0
            case 4:
                return endDatePickerVisible ? 200.0 : 0.0
            default:
                return super.tableView(tableView, heightForRowAt: indexPath)
            }
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    
    
    // MARK: Bar button item actions
    
    // Tapped "Cancel"
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    // Tapped "Done"
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        
        var filtersAdded = [EventFilterFactory.EventFilter]()
        
        
        // Date filter on?
        if dateSwitch.isOn {
            // Input check: At least one date must be selected.
            guard !(startDate == nil && endDate == nil) else {
                showErrorAlert(message: "Please select at least one date.")
                return
            }
            
            // Add date filter
            if startDate != nil, endDate != nil {
                // Filter between two dates
                do {
                    let newFilter = try EventFilterFactory.filterForEventsBetweenDates(startDate!, and: endDate!)
                    filtersAdded.append(newFilter)
                } catch EventFilterFactory.DateFilterError.invalidDateBounds {
                    showErrorAlert(message: "Start date and end date are invalid! Make sure the start date comes before the end date and try again.")
                    return
                } catch EventFilterFactory.DateFilterError.dateConversionError {
                    showErrorAlert(message: "There was an internal problem creating your date filter.")
                    return
                } catch {
                    showErrorAlert(message: error.localizedDescription)
                    return
                }
            } else if startDate != nil {
                // Filter after start date
                do {
                    let newFilter = try EventFilterFactory.filterForEventsAfterDate(startDate!)
                    filtersAdded.append(newFilter)
                } catch EventFilterFactory.DateFilterError.dateConversionError {
                    showErrorAlert(message: "There was an internal problem creating your date filter.")
                    return
                } catch {
                    showErrorAlert(message: error.localizedDescription)
                    return
                }
            } else if endDate != nil {
                // Filter after end date
                do {
                    let newFilter = try EventFilterFactory.filterForEventsBeforeDate(endDate!)
                    filtersAdded.append(newFilter)
                } catch EventFilterFactory.DateFilterError.dateConversionError {
                    showErrorAlert(message: "There was an internal problem creating your date filter.")
                    return
                } catch {
                    showErrorAlert(message: error.localizedDescription)
                    return
                }
            }
        }
        
        
        // Favorites filter on? (*** This should be the last filter checked because of the asynchronous database calls ***)
        if favoritesSwitch.isOn {
            // Add favorites filter
            if let currUser = Auth.auth().currentUser {
                DataService.instance.getFavoriteEventIDsForUser(withUID: currUser.uid, completion: { (eventIDs) in
                    print("Brennan - just retrieved \(String(describing: currUser.email))'s favorite events. About to execute the completion block now.)")
                    if eventIDs != nil {
                        // Successfully retrieved the favorite event IDs.
                        let newFilter = EventFilterFactory.filterForFavorites(inListOfEventIDs: eventIDs!)
                        filtersAdded.append(newFilter)
                        self.filtersCreated = filtersAdded.isEmpty ? nil : filtersAdded
                        self.performSegue(withIdentifier: "unwindToEventListVC", sender: nil)
                    } else {
                        // Didn't retrieve any favorite event IDs. No need to add this filter.
                        self.filtersCreated = filtersAdded.isEmpty ? nil : filtersAdded
                        self.performSegue(withIdentifier: "unwindToEventListVC", sender: nil)
                    }
                })
            } else {
                // TODO: There is no user logged in! (Shouldn't happen...)
            }
        } else {
            // No favorites filter and all done getting filters.
            self.filtersCreated = filtersAdded.isEmpty ? nil : filtersAdded
            self.performSegue(withIdentifier: "unwindToEventListVC", sender: nil)
        }
        
    }
    
    
    
    
    
    
}

