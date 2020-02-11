//
//  TaskDetailsViewController.swift
//  SaveMyTime
//  This class displays details of the task selected from the table view
//
//  Created by Terence Ng on 24/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit

// Class View where displaying a specific task after user clicked from TaskTableViewController
class TaskDetailsViewController: UIViewController{
    
    // represents the task that the user selected form the segue
    var passedTask: Task!
    
    weak var databaseController: DatabaseProtocol?

    // hold important references in the view
    @IBOutlet weak var taskTitleLabel: UILabel!
    @IBOutlet weak var taskSubjectLabel: UILabel!
    @IBOutlet weak var taskPercentLabel: UILabel!
    @IBOutlet weak var taskCompletionSlider: UISlider!
    @IBOutlet weak var taskDetailsLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the database controller once from the App Delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController
        
        taskTitleLabel.text = passedTask.taskTitle
        
        // retrieve the subject description from firebase
        databaseController?.getSubjectDescfromID(subjectID: passedTask.taskSubjectID) { (subjectString) -> Void in
            if let subjectString = subjectString {
                DispatchQueue.main.async {
                    self.taskSubjectLabel.text = subjectString
                }
            }
        }
        
        taskPercentLabel.text = "\(passedTask.taskPercentage)" + "% Complete"
        taskCompletionSlider.value = Float((passedTask.taskPercentage))
        taskDetailsLabel.text = passedTask.taskDesc
    }
    
    // updates the task percentage display whenver the user interacts with the slider
    @IBAction func sliderValueChanged(_ sender: Any) {
        taskPercentLabel.text = "\(Int(round(taskCompletionSlider.value)))% Complete"
        
        // update the task percentage Label
        // if task percentage reaches 100% - set taskCompleted property to true
        
        passedTask = databaseController?.updateTaskProgress(percentValue: Int(taskCompletionSlider.value), task: passedTask)
        
    }
    
    
    // delete task button
    // performs deletion in the database controller
    @IBAction func deleteTaskButton(_ sender: Any) {
        
        let deleteAlert = UIAlertController(title: "Confirm Deletion", message: "This Action will delete your Task.", preferredStyle: .alert)
        
        deleteAlert.addAction(UIAlertAction(title: "Yes", style: .default) { (action) -> Void in
            
            self.databaseController!.deleteTask(task: self.passedTask)
            self.displayMessage(title: "Success!", message: "Task has been successfully Deleted.")
        })
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(deleteAlert, animated: true, completion: nil)
    }
    
    // sends the task to edit task class
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "editTaskSegue" {
            
            let destination = segue.destination as! EditTaskViewController

            destination.passedTask = passedTask
        }
    }
    
    // Function which displays alerts
    func displayMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default) { (UIAlertAction) -> Void in
            
            // pop view controller
            CATransaction.begin()
            self.navigationController?.popViewController(animated: true)
            CATransaction.commit()
            
        })
        self.present(alertController, animated: true, completion: nil)
    }
}


    

    





