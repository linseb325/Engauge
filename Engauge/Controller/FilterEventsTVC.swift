//
//  FilterEventsTVC.swift
//  Engauge
//
//  Created by Brennan Linse on 3/13/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import UIKit

class FilterEventsTVC: UITableViewController {
    
    // MARK: Outlets
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    
    
    
    // MARK: Properties
    
    let formatter: DateFormatter = {
        let form = DateFormatter()
        form.timeStyle = .none
        form.dateStyle = .medium
        return form
    }()
    
    var startDate: Date? {
        didSet {
            if let newDate = startDate {
                startDateLabel.text = formatter.string(from: newDate)
            }
        }
    }
    
    var endDate: Date? {
        didSet {
            if let newDate = endDate {
                endDateLabel.text = formatter.string(from: newDate)
            }
        }
    }
    
    private var dateDisplaysVisible = false
    private var startDatePickerVisible = false
    private var endDatePickerVisible = false
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    
    // MARK: Date Pickers
    
    @IBAction func startDatePickerChanged(_ sender: UIDatePicker) {
        startDate = sender.date
    }
    
    @IBAction func endDatePickerChanged(_ sender: UIDatePicker) {
        endDate = sender.date
    }
    
    // Tapped a cell
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                if dateDisplaysVisible {
                    dateDisplaysVisible = false
                    startDatePickerVisible = false
                    endDatePickerVisible = false
                } else {
                    dateDisplaysVisible = true
                }
            case 1:
                startDatePickerVisible = !startDatePickerVisible
                startDate = startDatePicker.date
            case 3:
                endDatePickerVisible = !endDatePickerVisible
                endDate = endDatePicker.date
            default:
                return
            }
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
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
    
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        guard !(startDate == nil && endDate == nil) else {
            showErrorAlert(message: "Please select at least one date.")
            return
        }
        
        // TODO: Unwind back to the list of events
        
    }
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    
    
    
}

