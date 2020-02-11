//
//  EditTaskViewController.swift
//  SaveMyTime
//  This class allows user to edit their current task
//  standard functionality applies.
//
//  Created by Terence Ng on 25/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit

class EditTaskViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource  {
 
    // the task passed from the segue
    var passedTask: Task!
    
    // represents if task is successfully editted
    var success: Bool = false
    
    // reference to bottom constraint
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    weak var databaseController: DatabaseProtocol?
    
    // picker data for subjects
    var pickerData: [String] = [String]()
    
    // date picker for due date
    var datePicker: UIDatePicker?
    
    // store list of subjects
    var listOfSubjects: [Subject]?
    
    // represents the subject ID the user has selected
    var selectedSubjectID: String = ""
    
    // represents sorted list
    var orderedList: [Subject] = [Subject]()
    
    // get important references to the view's content
    @IBOutlet weak var taskTitleLabel: UITextField!
    @IBOutlet weak var taskDueDateLabel: UITextField!
    @IBOutlet weak var taskSubjectLabel: UITextField!
    @IBOutlet weak var taskDescLabel: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the database controller once from the App Delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(gestureRecognizer:)))
        view.addGestureRecognizer(tapGesture)
        
        // implement observers which push view up on keyboard popup
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        // observer which restores view back to normal when keyboard is dismissed
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // ensure text field implement their delegates for custom behaviour
        taskTitleLabel.delegate = self
        taskDueDateLabel.delegate = self
        taskSubjectLabel.delegate = self
        taskDescLabel.delegate = self
        
        taskTitleLabel.text = passedTask.taskTitle
        taskDescLabel.text = passedTask.taskDesc
        
        selectedSubjectID = passedTask.taskSubjectID
        
        databaseController?.getSubjectDescfromID(subjectID: passedTask.taskSubjectID) { (subjectString) -> Void in
            if let subjectString = subjectString {
                DispatchQueue.main.async {
                    self.taskSubjectLabel.text = subjectString
                }
            }
        }
    
        // Configure picker view for subject selection
        let taskPickerView = UIPickerView()
        taskSubjectLabel.inputView = taskPickerView
        taskPickerView.delegate = self
        taskPickerView.dataSource = self
        
        // configure datepicker view for date input
        // datepicker initial value should be the tasks's due date

        datePicker = UIDatePicker()
        datePicker?.datePickerMode = .date

        datePicker?.addTarget(self,action: #selector(dateChanged(datePicker:)), for: .valueChanged)
        
        view.addGestureRecognizer(tapGesture)
        taskDueDateLabel.inputView = datePicker
        
        // configure subject picker's data
        // call databaseController to retrieve list of subjects
        listOfSubjects = databaseController?.getAllSubjects()

        
        // loop list of subjects and display their unit code and title to the pickerView
        for subject in listOfSubjects! {
            
            if subject.id == selectedSubjectID {
                pickerData.insert(subject.subjectCode + " " + subject.subjectName, at: 0)
                orderedList.insert(subject, at: 0)
            } else {
                pickerData.append( subject.subjectCode + " " + subject.subjectName )
                orderedList.append(subject)
            }
        }
        
        // set a default value for subject picker
        taskSubjectLabel.text = pickerData.first
        
        // initial value for datepicker should be from the task due date set by user
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let taskDateObject = dateFormatter.date(from: passedTask!.dueDate)
        datePicker?.setDate(taskDateObject!, animated: true)
        taskDueDateLabel.text = passedTask!.dueDate
        
        // create underlined line for input textfield
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(origin: CGPoint(x: 0, y: taskTitleLabel.frame.height-10), size: CGSize(width: taskTitleLabel.frame.width, height: 0.5))
        bottomLine.backgroundColor = UIColor.white.cgColor
        taskTitleLabel.borderStyle = UITextField.BorderStyle.none
        taskTitleLabel.layer.addSublayer(bottomLine)
        
        // create underlined line for input textfield
        let bottomLine1 = CALayer()
        bottomLine1.frame = CGRect(origin: CGPoint(x: 0, y: taskDueDateLabel.frame.height-10), size: CGSize(width: taskDueDateLabel.frame.width, height: 0.5))
        bottomLine1.backgroundColor = UIColor.white.cgColor
        taskDueDateLabel.borderStyle = UITextField.BorderStyle.none
        taskDueDateLabel.layer.addSublayer(bottomLine1)
        
        // create underlined line for input textfield
        let bottomLine2 = CALayer()
        bottomLine2.frame = CGRect(origin: CGPoint(x: 0, y: taskSubjectLabel.frame.height-10), size: CGSize(width: taskSubjectLabel.frame.width, height: 0.5))
        bottomLine2.backgroundColor = UIColor.white.cgColor
        taskSubjectLabel.borderStyle = UITextField.BorderStyle.none
        taskSubjectLabel.layer.addSublayer(bottomLine2)
        
        // create underlined line for input textfield
        let bottomLine3 = CALayer()
        bottomLine3.frame = CGRect(origin: CGPoint(x: 0, y: taskDescLabel.frame.height-10), size: CGSize(width: taskDescLabel.frame.width, height: 0.5))
        bottomLine3.backgroundColor = UIColor.white.cgColor
        taskDescLabel.borderStyle = UITextField.BorderStyle.none
        taskDescLabel.layer.addSublayer(bottomLine3)

    }
    // function invoked on keyboard popup, pushes content up
    @objc func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        UIView.animate(withDuration: 0.1) { () -> Void in
            self.bottomConstraint.constant = keyboardFrame.size.height - 40
        }
    }
    
    // function invoked on keyboard dismissal, restores content back to normal
    @objc func keyboardWillHide(notification: NSNotification) {
        
        UIView.animate(withDuration: 0.1) { () -> Void in
            self.bottomConstraint.constant = 40
        }
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
        taskSubjectLabel.text = pickerData[row]
        
        if listOfSubjects?.count != 0 {
            selectedSubjectID = orderedList[row].id
            print(selectedSubjectID)
        }
    }
    // function invoked whenever the user interacts with the date picker
    // programmatically set the date value
    @objc func dateChanged(datePicker: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        taskDueDateLabel.text = dateFormatter.string(from: datePicker.date)
    }
    
    // Dismiss the keyboard when the return key is tapped
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    // function invoked when user taps on the view
    // dismisses any editing
    @objc func viewTapped(gestureRecognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    // Ensure user cannot type in keyboard for pickerview input
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == taskDueDateLabel || textField == taskSubjectLabel {
            return false
        }
        return true
    }
    
    
    @IBAction func clearAllLabel(_ sender: Any) {
        taskTitleLabel.text = ""
        taskDescLabel.text = ""
    }
    
    // function for updating the task
    // user validation occurs
    // if successful, pop the view controller
    @IBAction func updateTask(_ sender: Any) {
        
        // perform input validation in adding task
        
        guard listOfSubjects?.count != 0 else {
            displayMessage(title: "Please add a subject", message: "Head to settings page in order to manage your subjects")
            return
        }
        
        var validDate: Bool!
        var errorMsg = "Please Handle all Errors:\n"
        
        if taskTitleLabel.text == "" {
            errorMsg += "-Must Provide a Title for Task Title.\n" }
        
        if taskDueDateLabel.text == "" {
            errorMsg += "-Must Provide a Due Date for Task Due Date.\n"
        }
        
        if taskDueDateLabel.text != "" {
            
            validDate = determineValidDate()
            if validDate == false {
                errorMsg += "-Selected Date is prior to the current Date.\n"
            }
        }
        
        if taskSubjectLabel.text == "" {
            errorMsg += "-Must Provide a Subject for your Task.\n"
        }
        
        if taskDescLabel.text == "" {
            errorMsg += "-Must Provide a Description for Task Description.\n" }
        
        if taskTitleLabel.text != "" && taskSubjectLabel.text != "" && taskDescLabel.text != "" && validDate == true {
            
            success = true
            // editted Task
            
            
            print(selectedSubjectID)
            
            
            let newTask = Task(taskid: passedTask.taskid, taskTitle: taskTitleLabel.text!, taskDesc: taskDescLabel.text!, dueDate: taskDueDateLabel.text!, taskSubjectID: selectedSubjectID, taskPercentage: passedTask.taskPercentage, taskCompleted: passedTask.taskCompleted)
            
            databaseController?.updateTask(task: newTask)
            
            displayMessage(title: "Successful!", message: "You Have Successfully updated your Task.")
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
                let controller = self.navigationController?.viewControllers[(self.navigationController?.viewControllers.count)! - 3]
                self.navigationController?.popToViewController(controller!, animated: true)
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
        let selectedDateArr = taskDueDateLabel.text?.split(separator: "/")
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


