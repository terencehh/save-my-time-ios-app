//
//  AddTaskViewController.swift
//  SaveMyTime
//  This class handles Add Task functionality
//  Standard functionality such as user validation, add task button, and clear all button
//
//  Created by Terence Ng on 13/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit

// you've done a good job with the assignment but there are some issue with your app:
// there are no validation on the input field, date and status are accepting random characters and app is crashing
// date and status pickers are not properly implemented, should have default value already selected
// Cancel button should be there
// issue with date picker, it is disappearing with slightest of change.
// interface is not fine in smaller screens

// Akshay, I believe i have handled all your complaints of the portfolio assignment in this assignment!!

class AddTaskViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    // get reference to app delegates database
    weak var databaseController: DatabaseProtocol?

    // get important reference to text fields
    @IBOutlet weak var taskTitleTextField: UITextField!
    @IBOutlet weak var dueDateTextField: UITextField!
    @IBOutlet weak var subjectTextField: UITextField!
    @IBOutlet weak var taskDescriptionTextField: UITextField!
    
    // variable represents whether task is successfully added or not
    var success: Bool = false
    
    // get reference to bottom constraint
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    // picker data for subject selection
    var pickerData: [String] = [String]()
    
    // date picker for due date selection
    var datePicker: UIDatePicker?
    
    // holds list of subjects retrieved from database controller
    var listOfSubjects: [Subject]?
    
    // represents the initial selected subject ID
    var selectedSubjectID: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Get the database controller once from App Delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController
        
        // implement observers that push the view content up on keyboard display
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // ensure the text field implements delegates so that custom behaviours can be created
        taskTitleTextField.delegate = self
        dueDateTextField.delegate = self
        subjectTextField.delegate = self
        taskDescriptionTextField.delegate = self
        
        // Configure picker view for subject selection
        let subjectPickerView = UIPickerView()
        subjectTextField.inputView = subjectPickerView
        subjectPickerView.delegate = self
        subjectPickerView.dataSource = self
        
        // configure datepicker view for date input
        datePicker = UIDatePicker()
        datePicker?.datePickerMode = .date
        datePicker?.addTarget(self,action: #selector(dateChanged(datePicker:)), for: .valueChanged)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(gestureRecognizer:)))
        view.addGestureRecognizer(tapGesture)
        dueDateTextField.inputView = datePicker
        
        // configure subject picker's data
        
        // call databaseController to retrieve list of subjects
        listOfSubjects = databaseController?.getAllSubjects()
        
        // loop list of subjects and display their unit code and title to the pickerView
        
        if listOfSubjects?.count == 0 {
            pickerData = ["You have no subjects created."]
        } else {
            
            for subject in listOfSubjects! {
                pickerData.append( subject.subjectCode + " " + subject.subjectName )
            }
            // set a default value for subject picker
            subjectTextField.text = pickerData.first
            selectedSubjectID = listOfSubjects![0].id
        }
        
        // set a default value for Date picker
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        dueDateTextField.text = dateFormatter.string(from: datePicker!.date)
        
        
        // create underlined line for input textfield
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(origin: CGPoint(x: 0, y: taskTitleTextField.frame.height-10), size: CGSize(width: taskTitleTextField.frame.width, height: 0.5))
        bottomLine.backgroundColor = UIColor.white.cgColor
        taskTitleTextField.borderStyle = UITextField.BorderStyle.none
        taskTitleTextField.layer.addSublayer(bottomLine)
        
        // create underlined line for input textfield
        let bottomLine1 = CALayer()
        bottomLine1.frame = CGRect(origin: CGPoint(x: 0, y: dueDateTextField.frame.height-10), size: CGSize(width: dueDateTextField.frame.width, height: 0.5))
        bottomLine1.backgroundColor = UIColor.white.cgColor
        dueDateTextField.borderStyle = UITextField.BorderStyle.none
        dueDateTextField.layer.addSublayer(bottomLine1)
        
        // create underlined line for input textfield
        let bottomLine2 = CALayer()
        bottomLine2.frame = CGRect(origin: CGPoint(x: 0, y: subjectTextField.frame.height-10), size: CGSize(width: subjectTextField.frame.width, height: 0.5))
        bottomLine2.backgroundColor = UIColor.white.cgColor
        subjectTextField.borderStyle = UITextField.BorderStyle.none
        subjectTextField.layer.addSublayer(bottomLine2)
        
        // create underlined line for input textfield
        let bottomLine3 = CALayer()
        bottomLine3.frame = CGRect(origin: CGPoint(x: 0, y: taskDescriptionTextField.frame.height-10), size: CGSize(width: taskDescriptionTextField.frame.width, height: 0.5))
        bottomLine3.backgroundColor = UIColor.white.cgColor
        taskDescriptionTextField.borderStyle = UITextField.BorderStyle.none
        taskDescriptionTextField.layer.addSublayer(bottomLine3)
        
    }
    // function which ends any editing, invoked on tap gesture
    @objc func viewTapped(gestureRecognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    // function which invokes when keyboard pops, it pushes content up from keyboard
    @objc func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        UIView.animate(withDuration: 0.1) { () -> Void in
            self.bottomConstraint.constant = keyboardFrame.size.height - 40
        }
    }
    // function restores view content back to normal when keyboard hides
    @objc func keyboardWillHide(notification: NSNotification) {
        
        UIView.animate(withDuration: 0.1) { () -> Void in
            self.bottomConstraint.constant = 40
        }
    }
    
    // Ensure user cannot type in keyboard for pickerview input
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == dueDateTextField || textField == subjectTextField {
            return false
        }
        return true
    }
    
    // function invoked whenever datepicker is interacted on by the user
    // it sets the date to the value in the date picker
    @objc func dateChanged(datePicker: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        dueDateTextField.text = dateFormatter.string(from: datePicker.date)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        subjectTextField.text = pickerData[row]
        
        if listOfSubjects?.count != 0 {
            selectedSubjectID = listOfSubjects![row].id
        }
    }

    // Dismiss the keyboard when the return key is tapped
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    @IBAction func clearAllButton(_ sender: Any) {
        taskTitleTextField.text = ""
        taskDescriptionTextField.text = ""
    }
    
    // saves the task
    // validation is created to ensure no bugs occur
    @IBAction func saveTaskButton(_ sender: Any) {
        
        // perform input validation in adding task
        
        guard listOfSubjects?.count != 0 else {
            displayMessage(title: "Please add a subject", message: "Head to settings page in order to manage your subjects")
            return
        }
        
        var validDate: Bool!
        var errorMsg = "Please Handle all Errors:\n"
        
        if taskTitleTextField.text == "" {
            errorMsg += "-Must Provide a Title for Task Title.\n" }
        
        if dueDateTextField.text == "" {
            errorMsg += "-Must Provide a Due Date for Task Due Date.\n"
        }
        
        if dueDateTextField.text != "" {
            
            validDate = determineValidDate()
            if validDate == false {
                errorMsg += "-Selected Date is prior to the current Date.\n"
            }
        }
        
        if subjectTextField.text == "" {
            errorMsg += "-Must Provide a Subject for your Task.\n"
        }
        
        if taskDescriptionTextField.text == "" {
            errorMsg += "-Must Provide a Description for Task Description.\n" }
        

        
        if taskTitleTextField.text != "" && subjectTextField.text != "" && taskDescriptionTextField.text != "" && validDate == true {
            
            success = true
            // add new Task
            
            databaseController?.addNewTask(taskTitle: taskTitleTextField.text!, taskDesc: taskDescriptionTextField.text!, dueDate: dueDateTextField.text!, taskSubject: selectedSubjectID)

            displayMessage(title: "Successful!", message: "You Have Successfully Added the Task.")
        }
            
        else {
            displayMessage(title: "Error", message: errorMsg)
        }
    }
    
    // Function which displays alerts
    func displayMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default) { (UIAlertAction) -> Void in
            
            if self.success == true {
                // pop view controller
                CATransaction.begin()
                self.navigationController?.popViewController(animated: true)
                CATransaction.commit()
            }
        })
        self.present(alertController, animated: true, completion: nil)
    }
    
    // Custom made function for determining if a valid date is entered by the user
    // Taken from my previous portfolio iOS Assignment 2: Portfolio Exercises
    // Created by Terence Ng
    func determineValidDate() -> Bool {
        let currentDate = getCurrentDate()
        let selectedDateArr = dueDateTextField.text?.split(separator: "/")
        // M/D/Y
        
        let selectedYear = Int(selectedDateArr![2])
        let selectedMonth = Int(selectedDateArr![0])
        let selectedDay = Int(selectedDateArr![1])
        
        if selectedYear! < currentDate["Year"]! {
            return false
        }
        else if selectedYear! == currentDate["Year"]! {
            
            if selectedMonth! < currentDate["Month"]!{
                return false
            }
            else if selectedMonth! == currentDate["Month"]! {
                if selectedDay! < currentDate["Day"]! {
                    return false
                }
            }
        }
        return true
    }
    
    // Custom made function which retrieves the current date and stores it in a dictionary with keys year, month and day
    // Taken from my previous portfolio iOS Assignment 2: Portfolio Exercises
    // Created by Terence Ng
    func getCurrentDate() -> [String : Int] {
        
        var dateDict: [String:Int] = [:]
        
        let currentDate = Date()
        let calendar = Calendar.current
        let yearValue = calendar.component(.year, from: currentDate)
        let monthValue = calendar.component(.month, from: currentDate)
        let dayValue = calendar.component(.day, from: currentDate)
        
        dateDict.updateValue(yearValue, forKey: "Year")
        dateDict.updateValue(monthValue, forKey: "Month")
        dateDict.updateValue(dayValue, forKey: "Day")
        
        return dateDict
    }
}
