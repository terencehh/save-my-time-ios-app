//
//  SubjectTableViewController.swift
//  SaveMyTime
//  This class displays the user's subjects as a Table View Controller
//  Standard functionality applies like a normal table view.
//
//  Created by Terence Ng on 24/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit

class SubjectTableViewController: UITableViewController, UISearchResultsUpdating, DatabaseListener {
    
    
    // Retrieve important references to ensure table displays properly
    // when filtered or normal
    
    var subjectList: [Subject] = []
    var filteredSubjects: [Subject] = []
    var isFiltered: Bool = false
    var SECTION_SUBJECTS = 0
    var SECTION_COUNT = 1
    let CELL_SUBJECT = "subject"
    let CELL_COUNT = "subjectCount"
    
    var searchController: UISearchController?
    
    weak var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Get the database controller once from App Delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController
        
        filteredSubjects = subjectList
        
        // define search controller logic
        searchController = UISearchController(searchResultsController: nil)
        searchController!.searchResultsUpdater = self
        searchController!.obscuresBackgroundDuringPresentation = false
        searchController!.searchBar.placeholder = "Search Subjects"
        navigationItem.searchController = searchController
        
        definesPresentationContext = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // make sure tableview always reloads when subject is added/deleted/updated
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        if let searchText = searchController.searchBar.text?.lowercased(), searchText.count > 0 {
            filteredSubjects = subjectList.filter({(subject: Subject) -> Bool in
                
                if (subject.subjectName.lowercased().contains(searchText) == true) {
                    isFiltered = true
                } else {
                    isFiltered = false
                }
                
                return subject.subjectName.lowercased().contains(searchText)
            })
        }
        else {
            filteredSubjects = subjectList;
        }
        
        tableView.reloadData()
    }
    
    func searchBarIsEmpty() -> Bool {
        return searchController!.searchBar.text?.isEmpty ?? true
    }
    
    func isFiltering() -> Bool {
        return searchController!.isActive && !searchBarIsEmpty()
    }
    
    // Database Listener
    
    var listenerType = ListenerType.subject
    
    func onIncompleteTaskListChange(change: DatabaseChange, tasks: [Task]) {
        // not called
    }
    
    func onCompleteTaskListChange(change: DatabaseChange, tasks: [Task]) {
        // not called
    }
    
    func onSubjectListChange(change: DatabaseChange, subjects: [Subject]) {
        subjectList = subjects
        updateSearchResults(for: navigationItem.searchController!)
    }
    

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        if isFiltering() {
            return 1
        } else {
            return 2
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isFiltering() {
            return filteredSubjects.count
        } else {
            
            if section == SECTION_SUBJECTS {
                return subjectList.count
            }
            else {
                return 1
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if isFiltering() {
            
            let subjectCell = tableView.dequeueReusableCell(withIdentifier: CELL_SUBJECT, for: indexPath) as! SubjectTableViewCell
            let subject = filteredSubjects[indexPath.row]
            
            subjectCell.subjectCodeLabel.text = subject.subjectCode
            subjectCell.subjectNameLabel.text = subject.subjectName
            
            return subjectCell
            
        }
        
        else {
            
            if indexPath.section == SECTION_SUBJECTS && searchBarIsEmpty() {
                
                let subjectCell = tableView.dequeueReusableCell(withIdentifier: CELL_SUBJECT, for: indexPath) as! SubjectTableViewCell
                let subject = subjectList[indexPath.row]
                
                subjectCell.subjectCodeLabel.text = subject.subjectCode
                subjectCell.subjectNameLabel.text = subject.subjectName
                
                return subjectCell
            }
            
            else {
                
                let countCell = tableView.dequeueReusableCell(withIdentifier: CELL_COUNT, for: indexPath)
                
                if subjectList.count == 0 || subjectList.count == 1 {
                    countCell.textLabel?.text = "You currently have \(subjectList.count) subject."
                } else {
                    countCell.textLabel?.text = "You currently have \(subjectList.count) subjects."
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
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete && indexPath.section != SECTION_COUNT {
            
            var deletedSubject: Subject?
            
            if filteredSubjects.count != subjectList.count {
                deletedSubject = filteredSubjects[indexPath.row]
            }
            
            else {
                deletedSubject = subjectList[indexPath.row]
            }
            
            if deletedSubject != nil {
                databaseController!.deleteSubject(subject: deletedSubject!)
                tableView.reloadData()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "subjectDetailsSegue" {
            
            let destination = segue.destination as! EditSubjectViewController
            
            let selectedSubjectCell = sender as? SubjectTableViewCell
            let indexPath = tableView.indexPath(for: selectedSubjectCell!)
            
            if isFiltering() {
                let subject = filteredSubjects[indexPath!.row]
                destination.passedSubject = subject
            }
            
            else {
                let subject = subjectList[indexPath!.row]
                destination.passedSubject = subject
            }
        }
    }
}
