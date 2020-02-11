//
//  CompletedTaskTableViewController.swift
//  SaveMyTime
//  Table View Controller displaying completed tasks
//
//  Created by Terence Ng on 25/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit
import UserNotifications

class CompletedTaskTableViewController: UITableViewController, DatabaseListener, UISearchResultsUpdating {
    
    // store local lists for efficient table view display
    var taskList: [Task] = []
    var filteredTasks: [Task] = []
    
    var searchController: UISearchController?
    var isFiltered: Bool = false
    
    // get reference to table view sections
    var SECTION_TASK = 0
    var SECTION_COUNT = 1
    
    // get reference to cell identifiers
    let CELL_TASK = "taskCell"
    let CELL_COUNT = "cellCount"
    
    
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
        searchController!.searchBar.placeholder = "Search Complete Tasks"
        navigationItem.searchController = searchController
        
        definesPresentationContext = true
        databaseController?.addListener(listener: self)
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
    
    var listenerType = ListenerType.completetask
    
    func onIncompleteTaskListChange(change: DatabaseChange, tasks: [Task]) {
        // not called
    }
    
    func onSubjectListChange(change: DatabaseChange, subjects: [Subject]) {
        // not called
    }
    
    func onCompleteTaskListChange(change: DatabaseChange, tasks: [Task]) {
        taskList = tasks
        print("Retrieved Complete Task List", taskList)
        filteredTasks = taskList
        updateSearchResults(for: navigationItem.searchController!)
    }
    
    // updates the filtered task whenever search controller is interacted with
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
    
    // useful function to determine if search controller is active
    func searchBarIsEmpty() -> Bool {
        return searchController!.searchBar.text?.isEmpty ?? true
    }
    
    // useful function to determine if table is filtering
    func isFiltering() -> Bool {
        return searchController!.isActive && !searchBarIsEmpty()
    }
    
    // if filtering, return 1 section, else 2
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if isFiltering() {
            return 1
        }
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isFiltering() {
            return filteredTasks.count
        }
        
        else if section == SECTION_TASK {
            return taskList.count
        }
        
        else {
            return 1
        }
        
    }
    
    // if filtering, return the tasks from filteredTasks, else return tasks from normal taskList
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if isFiltering() {
            
            let taskCell = (tableView.dequeueReusableCell(withIdentifier: CELL_TASK, for: indexPath) as! TaskTableViewCell)
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
            return taskCell
        }
        
        else {
            
            if indexPath.section == SECTION_TASK && searchBarIsEmpty() {
                
                let taskCell = (tableView.dequeueReusableCell(withIdentifier: CELL_TASK, for: indexPath) as! TaskTableViewCell)
                let task = taskList[indexPath.row]
                taskCell.taskTitleLabel.text = task.taskTitle
                
                // retrieve the subject description from firebase
                databaseController?.getSubjectDescfromID(subjectID: task.taskSubjectID) { (subjectString) -> Void in
                    if let subjectString = subjectString {
                        DispatchQueue.main.async {
                            taskCell.subjectLabel.text = subjectString
                        }
                    }
                }
                return taskCell
                
            }
            
            let countCell = tableView.dequeueReusableCell(withIdentifier: CELL_COUNT, for: indexPath)
            
            
            if taskList.count == 0 || taskList.count == 1 {
                countCell.textLabel?.text = "You have \(taskList.count) Completed Task"
            } else {
                countCell.textLabel?.text = "You have \(taskList.count) Completed Tasks"
            }
            
            countCell.selectionStyle = .none
            countCell.textLabel?.textColor = UIColor.white
            return countCell
            
        }
    }

    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        if indexPath.section == SECTION_TASK {
            return true
        }
        return false
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete && indexPath.section != SECTION_COUNT {
            
            var deletedTask: Task?
            
            if filteredTasks.count != taskList.count {
                deletedTask = filteredTasks[indexPath.row]
            }
            
            else {
                deletedTask = taskList[indexPath.row]
                databaseController!.deleteTask(task: deletedTask!)
                tableView.reloadData()
            }
            
            if deletedTask != nil {
            databaseController!.deleteTask(task: deletedTask!)
            tableView.reloadData()
            
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "taskDetailsSegue" {
            
            let destination = segue.destination as! TaskDetailsViewController
            
            let selectedTaskCell = sender as? TaskTableViewCell
            
            let indexPath = tableView.indexPath(for: selectedTaskCell!)
            
            if isFiltering() {
                let task = filteredTasks[indexPath!.row]
                destination.passedTask = task
            }
            
            else {
                let task = taskList[indexPath!.row]
                destination.passedTask = task
            }
            

        }
    }
}

