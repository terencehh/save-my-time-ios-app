//
//  TaskTableViewController.swift
//  SaveMyTime
//  This class displays all current tasks the user has not finished yet
//  There are 3 main sections the table is split up, "Overdue", "Priority", and "Upcoming"
//  Over due tasks are shown first on top with higher priority, then in order goes down
//
//  Created by Terence Ng on 25/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit
import UserNotifications

class TaskTableViewController: UITableViewController, DatabaseListener, UISearchResultsUpdating {
    
    // Initialize local lists to store and display
    var taskList: [Task] = [Task]()
    var filteredTasks: [Task] = [Task]()
    
    // variable checking if table is filtered currently
    var isFiltered: Bool = false
    
    // Initialize references to sections
    var SECTION_OVERDUE = 0
    var SECTION_PRIORITY = 1
    var SECTION_UPCOMING = 2
    var SECTION_COUNT = 3
    
    // Get reference to cell identifiers
    let CELL_OVERDUE = "overdueTasks"
    let CELL_PRIORITY = "priorityTasks"
    let CELL_UPCOMING = "upcomingTasks"
    let CELL_COUNT = "taskCount"
    
    // define a search controller later to allow for efficient searching
    var searchController: UISearchController?
    
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
        searchController = UISearchController(searchResultsController: nil)
        searchController!.searchResultsUpdater = self
        searchController!.obscuresBackgroundDuringPresentation = false
        searchController!.searchBar.placeholder = "Search Tasks"
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

        sortedTaskList = databaseController!.sortTaskList(taskList: taskList)
        filteredTasks = taskList
        
        print("retrieved task list", taskList)
        updateSearchResults(for: navigationItem.searchController!)
    }
    
    func onSubjectListChange(change: DatabaseChange, subjects: [Subject]) {
        // not called
    }
    
    func onCompleteTaskListChange(change: DatabaseChange, tasks: [Task]) {
        // not called
    }
    
    // updates the filtered list whenever user types on search bar
    func updateSearchResults(for searchController: UISearchController) {
        
        if let searchText = searchController.searchBar.text?.lowercased(), searchText.count > 0 {
            
            filteredTasks = taskList.filter({(task: Task) -> Bool in
                
                if task.taskTitle.lowercased().contains(searchText.lowercased()) == true {
                    isFiltered = true
                } else {
                    isFiltered = false
                }
                
                return task.taskTitle.lowercased().contains(searchText.lowercased())
            })
        }
            
        else {
            filteredTasks = taskList;
        }
        
        tableView.reloadData()
    }
    
    // useful functions to check if search bar is empty
    func searchBarIsEmpty() -> Bool {
        return searchController!.searchBar.text?.isEmpty ?? true
    }
    
    // useful function to check if currently filtering
    func isFiltering() -> Bool {
        return searchController!.isActive && !searchBarIsEmpty()
    }

    // if filtering, return 1 section for filtered tasks, else return 4
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if isFiltering() {
            return 1
        } else {
            return 4
        }

    }

    // if filtering, return amount of filtered tasks, else return amount of types of tasks for each section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isFiltering() {
            return filteredTasks.count
        }
            
        else {
            
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
    }

    // if filtered, return tasks in filtered list
    // if not, then check all 3 categories of tasks, also return the task count
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if isFiltering() {
            let taskCell = (tableView.dequeueReusableCell(withIdentifier: CELL_OVERDUE, for: indexPath) as! TaskTableViewCell)
            let task = filteredTasks[indexPath.row]
            taskCell.taskTitleLabel.text = task.taskTitle
            
            // retrieve the subject description from firebase
            databaseController?.getSubjectDescfromID(subjectID: task.taskSubjectID) { (subjectString) -> Void in
                if let subjectString = subjectString {
                    DispatchQueue.main.async {
                        taskCell.subjectLabel.text = subjectString
                    }
                }
            }
            
            taskCell.dueDescriptionLabel!.text = getDueDescription(dateString: task.dueDate)
            taskCell.dueDescriptionLabel!.textColor = UIColor.white
            
            return taskCell
        }
        
        else {
            // TODO - Perform font highlights to distinguish between priority tasks vs upcoming tasks
            if indexPath.section == SECTION_OVERDUE && searchBarIsEmpty() {
                
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
                
                taskCell.dueDescriptionLabel!.text = getDueDescription(dateString: task.dueDate)
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
                
                taskCell.dueDescriptionLabel!.text = getDueDescription(dateString: task.dueDate)
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
                
                taskCell.dueDescriptionLabel!.text = getDueDescription(dateString: task.dueDate)
                
                return taskCell
            }
            
            else {
                
                let countCell = tableView.dequeueReusableCell(withIdentifier: CELL_COUNT, for: indexPath)
                
                if taskList.count == 0 || taskList.count == 1 {
                    countCell.textLabel?.text = "You currently have \(taskList.count) Task"
                } else {
                    countCell.textLabel?.text = "You currently have \(taskList.count) Tasks"
                }
                
                countCell.selectionStyle = .none
                countCell.textLabel?.textColor = UIColor.white
                return countCell
                
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        if indexPath.section != SECTION_COUNT {
            return true
        }
        return false
    }
    
    
    // determines the task to delete
    // as I store a sorted list which separates tasks into specific categories, I will need to search the specific
    // index in my sortedList
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete && indexPath.section != SECTION_COUNT {
            
            var deletedTask: Task?
            
            if filteredTasks.count != taskList.count {
                deletedTask = filteredTasks[indexPath.row]
            }
            
            else {
                
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
            }
        
            if deletedTask != nil {
                databaseController!.deleteTask(task: deletedTask!)
                tableView.reloadData()
            }
        }
    }
    
    // function which outputs the current description showing dueDate
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
    
    // pass the correct task to show more details in the TaskDetailsViewController class
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "taskDetailsSegue" {
            
            let destination = segue.destination as! TaskDetailsViewController
            
            let selectedTaskCell = sender as? TaskTableViewCell

            let indexPath = tableView.indexPath(for: selectedTaskCell!)
            
            // find the correct task section
            var section: Int?
            
            if isFiltering() {
                let task = filteredTasks[indexPath!.row]
                destination.passedTask = task
            }
            
            else {
                
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
}

