//
//  TaskTableViewController.swift
//  SaveMyTime
//
//  Created by Terence Ng on 25/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit
import UserNotifications

class TaskTableViewController: UITableViewController, DatabaseListener, UISearchResultsUpdating {
    
    var taskList: [Task] = []
    var filteredTasks: [Task] = []
    
    var SECTION_OVERDUE = 0
    var SECTION_PRIORITY = 1
    var SECTION_UPCOMING = 2
    var SECTION_COUNT = 3
    
    let CELL_OVERDUE = "overdueTasks"
    let CELL_PRIORITY = "priorityTasks"
    let CELL_UPCOMING = "upcomingTasks"
    let CELL_COUNT = "taskCount"
    
    // This stores multiple tasks into their category - overdue, priority, and upcoming
    var sortedTaskList: [[Task]] = []
    
    // background task identifier for fetching tasks about to be due
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    weak var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the database controller once from the App Delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController

        filteredTasks = taskList
        
        // define search controller logic
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Tasks"
        navigationItem.searchController = searchController
        
        definesPresentationContext = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // make sure tableview always reloads when subject is added/deleted/updated
        super.viewWillAppear(animated)
        
        print("printing task when view appeared", taskList)

        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    
    // Database Listener
    
    var listenerType = ListenerType.incompletetask
    
    func onIncompleteTaskListChange(change: DatabaseChange, tasks: [Task]) {
        print("lalala, incomplete")
        taskList = tasks

        sortedTaskList = sortTaskList(taskList: taskList)
        
        print("retrieved task list", taskList)
        updateSearchResults(for: navigationItem.searchController!)
    }
    
    func onSubjectListChange(change: DatabaseChange, subjects: [Subject]) {
        // not called
    }
    
    func onCompleteTaskListChange(change: DatabaseChange, tasks: [Task]) {
        // not called
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text?.lowercased(), searchText.count > 0 {
            filteredTasks = taskList.filter({(task: Task) -> Bool in
                return task.taskTitle.lowercased().contains(searchText)
            })
        }
        else {
            filteredTasks = taskList;
        }
        
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == SECTION_OVERDUE {
            return sortedTaskList[0].count
        }
        
        else if section == SECTION_PRIORITY {
            return sortedTaskList[1].count
        }
        
        else if section == SECTION_UPCOMING {
            return sortedTaskList[2].count
        }
        
        else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        // TODO - Perform font highlights to distinguish between priority tasks vs upcoming tasks
        if indexPath.section == SECTION_OVERDUE {
            
            let taskCell = (tableView.dequeueReusableCell(withIdentifier: CELL_OVERDUE, for: indexPath) as! TaskTableViewCell)
            let task = sortedTaskList[0][indexPath.row]
            taskCell.taskTitleLabel.text = task.taskTitle
            
            // retrieve the subject description from firebase
            databaseController?.getSubjectDescfromID(subjectID: task.taskSubjectID) { (subjectString) -> Void in
                if let subjectString = subjectString {
                    DispatchQueue.main.async {
                        taskCell.subjectLabel.text = subjectString
                    }
                }
            }

            taskCell.dueDescriptionLabel.text = getDueDescription(dateString: task.dueDate)
            return taskCell
        }
        
        else if indexPath.section == SECTION_PRIORITY {
            let taskCell = (tableView.dequeueReusableCell(withIdentifier: CELL_PRIORITY, for: indexPath) as! TaskTableViewCell)
            let task = sortedTaskList[1][indexPath.row]
            taskCell.taskTitleLabel.text = task.taskTitle
            
            // retrieve the subject description from firebase
            databaseController?.getSubjectDescfromID(subjectID: task.taskSubjectID) { (subjectString) -> Void in
                if let subjectString = subjectString {
                    DispatchQueue.main.async {
                        taskCell.subjectLabel.text = subjectString
                    }
                }
            }
            
            taskCell.dueDescriptionLabel.text = getDueDescription(dateString: task.dueDate)
            return taskCell
        }
        
        else if indexPath.section == SECTION_UPCOMING {
            
            let taskCell = tableView.dequeueReusableCell(withIdentifier: CELL_UPCOMING, for: indexPath) as! TaskTableViewCell
            let task = sortedTaskList[2][indexPath.row]
            
            taskCell.taskTitleLabel.text = task.taskTitle
            
            // retrieve the subject description from firebase
            databaseController?.getSubjectDescfromID(subjectID: task.taskSubjectID) { (subjectString) -> Void in
                if let subjectString = subjectString {
                    DispatchQueue.main.async {
                        taskCell.subjectLabel.text = subjectString
                    }
                }
            }
            
            taskCell.dueDescriptionLabel.text = getDueDescription(dateString: task.dueDate)
            
            return taskCell
        }

        let countCell = tableView.dequeueReusableCell(withIdentifier: CELL_COUNT, for: indexPath)
        
        
        if taskList.count == 0 || taskList.count == 1 {
            countCell.textLabel?.text = "You currently have \(taskList.count) Task"
        } else {
            countCell.textLabel?.text = "You currently have \(taskList.count) Tasks"
        }
        
        countCell.selectionStyle = .none
        return countCell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        if indexPath.section == SECTION_PRIORITY || indexPath.section == SECTION_OVERDUE || indexPath.section == SECTION_UPCOMING {
            return true
        }
        return false
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete && indexPath.section != SECTION_COUNT {
            
            var deletedTask: Task?
            
            switch(indexPath.section) {
                
            case SECTION_OVERDUE:
                deletedTask = sortedTaskList[0][indexPath.row]
                break
                
            case SECTION_PRIORITY:
                deletedTask = sortedTaskList[1][indexPath.row]
                break
            case SECTION_UPCOMING:
                deletedTask = sortedTaskList[2][indexPath.row]
                break
                
            default:
                break
            }
            
            if deletedTask != nil {
                databaseController!.deleteTask(task: deletedTask!)
                tableView.reloadData()
            }
        }
    }
    
    func getDueDescription(dateString: String) -> String {
        
        // get the difference between current date and due date

        let currentDate = Date()
        // convert task date string into a date object for comparison
        let dateFormat = "MM/dd/yyyy"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        
        let taskDueDate = dateFormatter.date(from: dateString)?.addingTimeInterval(86400)
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day]
        formatter.unitsStyle = .full
        let differenceString = formatter.string(from: currentDate, to: taskDueDate!)
        
        if differenceString!.contains("-") {
            
            let startingIndex = differenceString?.index((differenceString?.firstIndex(of: "-"))!, offsetBy: 1)
            let endingIndex = differenceString?.index(differenceString!.endIndex, offsetBy: 0)

            return "Overdue by \(differenceString![startingIndex!..<endingIndex!])"
        } else {
            return "Due in \(differenceString!)"
        }
    }

    func sortTaskList(taskList: [Task]) -> [[Task]] {
        
        var overdueTasks: [Task] = []
        var priorityTasks: [Task] = []
        var upcomingTasks: [Task] = []
        
        
        // loop through all tasks in taskList
        // categorize them into 3 different task lists
        
        // convert my date string into Date object to perform comparison
        let dateFormat = "MM/dd/yyyy"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        
        let currentDate = Date()
        
        let twoWeeksPast = Calendar.current.date(byAdding: .day, value: 14, to: currentDate)

        for task in taskList {


            let taskDueDate = dateFormatter.date(from: task.dueDate)
            
            // if overdue
            if currentDate > taskDueDate! {
                overdueTasks.append(task)
            }
            
            // if due within two weeks
            else if twoWeeksPast! > taskDueDate! {
                priorityTasks.append(task)
            }
            
            // if not due within two weeks
            else {
                upcomingTasks.append(task)
            }
        }
        
        return [overdueTasks, priorityTasks, upcomingTasks]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "taskDetailsSegue" {
            
            let destination = segue.destination as! TaskDetailsViewController
            
            let selectedTaskCell = sender as? TaskTableViewCell

            let indexPath = tableView.indexPath(for: selectedTaskCell!)
            
            // find the correct task section
            var section: Int?
            
            switch(indexPath!.section) {
                
            case SECTION_OVERDUE:
                section = 0
                break
            case SECTION_PRIORITY:
                section = 1
                break
            case SECTION_UPCOMING:
                section = 2
                break
            default:
                break
            }

            let task = sortedTaskList[section!][indexPath!.row]
            destination.passedTask = task
        }
    }
}

