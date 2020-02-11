//
//  MainFocusPageViewController.swift
//  SaveMyTime

//  This class handles the main functionality of the app which is
//  Allowing Users to schedule "focus sessions" for tasks, where procrastionation is detected
//  using Core Motion, and in response, alarms, vibrations and notifications will be employed to prevent users
//  to procrastinate.
//
//  Asides from detecting when the user holds the phone via Core Motion, We also detect when the user
//  Enters the background while a focus session is active via AppDelegate's lifecycle methods. this also
//  Allows us to detect when the user is procrastinating, and hence alarms, notifications, and vibrations will
//  occur as well.
//
//  DESIGN CHOICES:
//
//  There is no way to STOP a focus session to ensure users are committed to their session.
//  Users MAY take a break, However they must resume and COMPLETE their session in order to get a good record

//  Created by Terence Ng on 3/6/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit
import UserNotifications
import CoreMotion
import AudioToolbox
import FirebaseAuth
import AVFoundation

class MainFocusPageViewController: UIViewController, DatabaseListener, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    // get reference to current user
    var currentUser = Auth.auth().currentUser
    
    // get reference to bottom constraint
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    // get a reference to App Delegate's notification and notification Center class
    var notifications: Notification?
    var notificationCenter: UNUserNotificationCenter?
    
    @IBOutlet weak var focusTimeLabel: UILabel!
    @IBOutlet weak var taskPickedLabel: UITextField!
    @IBOutlet weak var subjectPickedLabel: UITextField!
    @IBOutlet weak var timerLabel: UITextField!
    
    var taskPickerView: UIPickerView!
    var subjectPickerView: UIPickerView!
    var datePickerView: UIDatePicker!
    
    // Configure the countdown timer for focus sessions
    var timer = Timer()
    var isTimerRunning = false
    var resumeTapped = false
    
    // Default time interval for a focus session is 5 minutes
    var timeInterval: Int = 60 * 5
    
    // This displays the value when counting down
    var countDown: Int = 0
    // Store the original screen brightness before session began
    var originalBrightness: CGFloat = UIScreen.main.brightness
    
    @IBOutlet weak var beginSession: UIButton!
    @IBOutlet weak var pauseSession: UIButton!
    
    var taskPickerData: [String] = [String]()
    var subjectPickerData: [String] = [String]()
    
    // Retrieve all user tasks
    var allTasks: [Task]?
    
    // store all user subjects
    var allSubjects: [Subject]?
    
    // this stores the user tasks which corresponds to a specific subject
    var listOfTasks: [Task]?
    
    // this stores the subject selected by the user in the picker view
    var selectedSubjectID: String = ""
    
    // this stores the task selected by the user for performing the focus session
    var selectedTaskID: String = ""
    
    // motionManager tracks device motion to prevent user from touching their phone during a focus session.
    // Only gets instantiated when focus session begins.
    var motionManager: CMMotionManager?
    
    // Variable stores amount of times user has violated by using his phone during an ongoing focus session
    var violation: Int = 0
    
    // Displays the user's current focus time in minutes
    var currentFocusedTime: Int = 0
    
    // stores the main colors needed
    var greyColor: UIColor?
    var pinkColor: UIColor?
    
    weak var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pauseSession.setTitle("", for: .normal)
        subjectPickerView = UIPickerView()
        taskPickerView = UIPickerView()
        datePickerView = UIDatePicker()
        
        // Get the database controller once from the App Delegate
        // Also get the notification and notification center
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController
        self.notifications = appDelegate.notification!
        self.notificationCenter = appDelegate.notificationCenter
        
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
//
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        let dateString = dateFormatter.string(from: Date())
        
        greyColor = beginSession.backgroundColor!
        pinkColor = subjectPickerView.backgroundColor!
        
        
        // Retrieve the current focus time the user has done of the day
        databaseController!.getFocussedTime(date: dateString) { (focusTime) -> Void in
            if let focusTime = focusTime {
                DispatchQueue.main.async {
                    self.currentFocusedTime = self.secondsToMinutes(seconds: focusTime)
                    self.focusTimeLabel.text = "You have stayed focus focus for \(self.currentFocusedTime) minutes today."
                }
            }
        }
        
        databaseController?.setTimerRunning(active: false)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(gestureRecognizer:)))
        view.addGestureRecognizer(tapGesture)
        
        // Remove the back button as this is the main page
        self.navigationItem.setHidesBackButton(true, animated: true)
        view.addGestureRecognizer(tapGesture)
        
        // Configure picker view for subject selection
        subjectPickedLabel.inputView = subjectPickerView
        subjectPickerView.delegate = self
        subjectPickerView.dataSource = self
        
        // Configure picker view for task selection
        taskPickedLabel.inputView = taskPickerView
        taskPickerView.delegate = self
        taskPickerView.dataSource = self
        // Configure picker view for time selection
        timerLabel.inputView = datePickerView
        datePickerView.datePickerMode = .countDownTimer
        datePickerView.minuteInterval = 5
        // Initially, time is set to 5 minutes
        timerLabel.text = "0 Hours 5 Minutes"
        datePickerView.addTarget(self, action: #selector(datePickerChanged(picker:)), for: .valueChanged)
        
        // Initially, not possible to pause a focus session
        pauseSession.isEnabled = false
        
        subjectPickedLabel.delegate = self
        taskPickedLabel.delegate = self
        timerLabel.delegate = self
        
        
        // create underlined line for input textfield
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(origin: CGPoint(x: 0, y: subjectPickedLabel.frame.height-5), size: CGSize(width: subjectPickedLabel.frame.width, height: 0.5))
        bottomLine.backgroundColor = UIColor.white.cgColor
        subjectPickedLabel.borderStyle = UITextField.BorderStyle.none
        subjectPickedLabel.layer.addSublayer(bottomLine)
        
        let bottomLine1 = CALayer()
        // create underlined line for input textfield
        bottomLine1.frame = CGRect(origin: CGPoint(x: 0, y: taskPickedLabel.frame.height-5), size: CGSize(width: taskPickedLabel.frame.width, height: 0.5))
        bottomLine1.backgroundColor = UIColor.white.cgColor
        taskPickedLabel.borderStyle = UITextField.BorderStyle.none
        taskPickedLabel.layer.addSublayer(bottomLine1)
        
        let bottomLine2 = CALayer()
        // create underlined line for input textfield
        bottomLine2.frame = CGRect(origin: CGPoint(x: 0, y: timerLabel.frame.height-5), size: CGSize(width: timerLabel.frame.width, height: 0.5))
        bottomLine2.backgroundColor = UIColor.white.cgColor
        timerLabel.borderStyle = UITextField.BorderStyle.none
        timerLabel.layer.addSublayer(bottomLine2)
    }
    
    // Dismiss the keyboard when the return key is tapped
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    @objc func viewTapped(gestureRecognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
//    @objc func keyboardWillShow(notification: NSNotification) {
//        let info = notification.userInfo!
//        let keyboardFrame: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
//
//        UIView.animate(withDuration: 0.1) { () -> Void in
//            self.bottomConstraint.constant = keyboardFrame.size.height
//        }
//    }
//
//    @objc func keyboardWillHide(notification: NSNotification) {
//
//        UIView.animate(withDuration: 0.1) { () -> Void in
//            self.bottomConstraint.constant = 40
//        }
//    }
    
    // Database Listener
    var listenerType = ListenerType.all
    
    override func viewWillAppear(_ animated: Bool) {
        // make sure tableview always reloads when subject is added/deleted/updated
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
        
        // configure subject picker's data
        // call databaseController to retrieve list of subjects
        if allSubjects!.count == 0 {
            subjectPickerData = ["You have no Subjects."]
            taskPickerData = ["You have no Tasks."]

        } else {
            // loop list of subjects and display their unit code and title to the pickerView
            for subject in allSubjects! {
                subjectPickerData.append( subject.subjectCode + " " + subject.subjectName )
            }
            
            // Store default selected subject's ID
            selectedSubjectID = allSubjects!.first!.id
            
            // configure task picker's data
            // retrieve list of tasks with the specified subject id
            listOfTasks = getTaskWithSubjectID(subjectID: selectedSubjectID)
  
            if listOfTasks!.count == 0 {
                taskPickerData = ["You have no Tasks."]
            }
            else {
                for task in listOfTasks! {
                    taskPickerData.append( task.taskTitle + " " + "\(task.taskPercentage)%" )
                }
                selectedTaskID = listOfTasks!.first!.taskid
            }
        }
        
        // set a default value for subject label
        subjectPickedLabel.text = subjectPickerData.first
        // set a default value for task label
        taskPickedLabel.text = taskPickerData.first
        
        print("Initial Subject ID", selectedSubjectID)
        print("Initial Task ID", selectedTaskID)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        let dateString = dateFormatter.string(from: Date())
        
        databaseController!.getFocussedTime(date: dateString) { (focusTime) -> Void in
            if let focusTime = focusTime {
                DispatchQueue.main.async {
                    self.currentFocusedTime = self.secondsToMinutes(seconds: focusTime)
                    self.focusTimeLabel.text = "You have stayed focus for \(self.currentFocusedTime) minutes today."
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        subjectPickerData = []
        taskPickerData = []
        
        databaseController?.removeListener(listener: self)
    }
    
    
    
    func onIncompleteTaskListChange(change: DatabaseChange, tasks: [Task]) {
        allTasks = tasks
    }
    
    func onCompleteTaskListChange(change: DatabaseChange, tasks: [Task]) {
        // not called
    }
    
    func secondsToMinutes(seconds: Int) -> Int {
        return seconds / 60
    }
    
    func onSubjectListChange(change: DatabaseChange, subjects: [Subject]) {
        allSubjects = subjects
    }
    
    // Retrieve all tasks with a subject ID
    // This is done locally for efficiency
    func getTaskWithSubjectID(subjectID: String) -> [Task] {
        
        var outputList = [Task]()
        
        for task in allTasks! {
            if task.taskSubjectID == subjectID && task.taskCompleted == false {
                outputList.append(task)
            }
        }
        return outputList
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if pickerView == subjectPickerView {
            return subjectPickerData.count
        }
        else {
            return taskPickerData.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if pickerView == subjectPickerView {
            return subjectPickerData[row]
        }
        else {
            return taskPickerData[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if pickerView == subjectPickerView {
            
            subjectPickedLabel.text = subjectPickerData[row]
            
            if allSubjects!.count != 0 {
                selectedSubjectID = allSubjects![row].id
                
                // re-generate the list of tasks based on the new chosen subject
                listOfTasks = getTaskWithSubjectID(subjectID: selectedSubjectID)
                
                if listOfTasks!.count == 0 {
                    taskPickerData = ["You have no Tasks."]
                    selectedTaskID = ""
                    taskPickedLabel.text = taskPickerData.first
                } else {
                    taskPickerData = []
                    for task in listOfTasks! {
                        taskPickerData.append( task.taskTitle + " " + "\(task.taskPercentage)%" )
                    }
                    taskPickedLabel.text = taskPickerData.first
                    selectedTaskID = listOfTasks!.first!.taskid
                }
            } else {
                selectedSubjectID = ""
            }
        }
        
        else {
            taskPickedLabel.text = taskPickerData[row]
            selectedTaskID = listOfTasks![row].taskid
        }
        
        print("Selected Subject ID", selectedSubjectID)
        print("Selected Task ID", selectedTaskID)
        
    }
    
    @objc func datePickerChanged(picker: UIDatePicker) {
        print(picker.date)
        
        let calendar = Calendar.current
        
        let hours = calendar.component(.hour, from: picker.date)
        let minutes = calendar.component(.minute, from: picker.date)
        print(hours, minutes)
        
        
        timeInterval = computeTimeInterval(hour: hours, minute: minutes)
        
        timerLabel.text = "\(String(hours)) Hours \(String(minutes)) Minutes"
    }
    
    // Ensure user cannot type in keyboard for pickerview input
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return false
    }
    
    func computeTimeInterval(hour: Int, minute: Int) -> Int {
        
        var outputInSeconds = 0
        
        if hour != 0 {
            outputInSeconds += (3600 * hour)
        }
        
        if minute != 0 {
            outputInSeconds += (60 * minute)
        }
        
        return outputInSeconds
    }
    
    // function for formatting a string via seconds
    // Taken and modified from https://stackoverflow.com/questions/52215882/ios-how-to-create-countdown-time-hours-minutes-seccond-swift-4
    func timeString(time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
    }
    
    // function when timer is run
    func runTimer() {
        databaseController!.setFocusSession(active: true)
        databaseController!.setTimerRunning(active: true)
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(updateTimer)), userInfo: nil, repeats: true)
        isTimerRunning = true
        self.pauseSession.isEnabled = true
        pauseSession.setTitle("Take a Break", for: .normal)
    }

    // function to update timer
    @objc func updateTimer() {
        
        if countDown < 1 {
            timer.invalidate()
            
            // Display notification to user
            let content = UNMutableNotificationContent()
            content.title = "Times up!"
            
            let success = databaseController!.getFocusSession()

            
            var successMessage: String?
            
            if success == true {
                successMessage = "You have completed your Focus Session. Good Job!"
                focusTimeLabel.text = "You have stayed focus for \(currentFocusedTime + secondsToMinutes(seconds: timeInterval)) minutes today."
            } else {
                successMessage = "You have failed your Focus Session. Good Luck next time!"
            }
            
            content.body = successMessage!
            
            databaseController!.setTimerRunning(active: false)
            databaseController!.setFocusSession(active: false)
            
            // enable navigation to other tab bar controllers
            self.tabBarController!.tabBar.items!.forEach{ $0.isEnabled = true }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd-yyyy"
            let dateString = dateFormatter.string(from: Date())
            
            // Send data to firebase to store the results of the focus session
            self.databaseController?.updateFocusSessionCompletion(date: dateString, success: success, focusTime: self.timeInterval)
            
            // stop device motion
            motionManager?.stopDeviceMotionUpdates()
            
            // Create the notification trigger
            let date = Date().addingTimeInterval(10)
            
            let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            // Create the notification request
            let identifier = UUID().uuidString
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            // Register the request
            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
            
            // Reset the current timer
            self.beginSession.isEnabled = true
            self.beginSession.setTitle("Begin Session", for: .normal)
            self.beginSession.backgroundColor = greyColor
            timerLabel.text = timeString(time: TimeInterval(timeInterval))
            isTimerRunning = false
            self.pauseSession.setTitle("", for: .normal)
            self.pauseSession.backgroundColor = pinkColor
            self.pauseSession.isEnabled = false
            
            // re-enable the text fields
            self.subjectPickedLabel.isEnabled = true
            self.taskPickedLabel.isEnabled = true
            self.timerLabel.isEnabled = true
            
            // proximity display back to normal
            UIDevice.current.isProximityMonitoringEnabled = false
            
            // display idle back to normal
            UIApplication.shared.isIdleTimerDisabled = false
            
            // play vibration on phone
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            
            // Send a message to user to indicate session is over
            displayMessage(title: "Times Up!", message: successMessage!)
            
        } else {
            countDown -= 1
            timerLabel.text = timeString(time: TimeInterval(countDown))
        }
    }


    // function to pause timer, This allows the phone to not ring when the user is taking a break
    @IBAction func pauseSession(_ sender: Any) {
        if self.resumeTapped == false {
            timer.invalidate()
            databaseController!.setFocusSession(active: false)
            motionManager?.stopDeviceMotionUpdates()
            
            // proximity display back to normal
            UIDevice.current.isProximityMonitoringEnabled = false
            
            // display idle back to normal
            UIApplication.shared.isIdleTimerDisabled = false
            
            UIScreen.main.brightness = originalBrightness
            
            databaseController!.setTimerRunning(active: false)
            
            self.resumeTapped = true
            self.pauseSession.setTitle("Resume Session", for: .normal)
        } else {
            
            // enable idle display
            UIDevice.current.isProximityMonitoringEnabled = true
            
            // enabling idle display
            UIApplication.shared.isIdleTimerDisabled = true
            
            
            runTimer()
            databaseController!.setFocusSession(active: true)
            databaseController!.setTimerRunning(active: true)
            self.resumeTapped = false
            // restart motion sensor class
            startMotionSensor()
            self.pauseSession.setTitle("Take a Break", for: .normal)
        }
    }
    
    // Starts the session if every validation is passed
    // User is greeted to ensure they follow the rules of focus session
    // Core Motion is initialized after successful startup
    @IBAction func startSession(_ sender: Any) {
        
        // PERFORM Validation to ensure
        // Subject Exists, Task Exists, and Time is specified above 0:00 min
        
        guard allSubjects?.count != 0 else {
            displayMessage(title: "Please add a subject", message: "Head to Setting page in order to manage your subjects.")
            return
        }
        
        guard listOfTasks?.count != 0 else {
            displayMessage(title: "Please add a task for your subject", message: "Head to Task page in order to manage your tasks.")
            return
        }
        
        var errorMsg = "Please Handle all Errors:\n"
        
        if subjectPickedLabel.text == "" {
            errorMsg += "-Must Provide a Subject.\n" }
        
        if taskPickedLabel.text == "" {
            errorMsg += "-Must Provide a Task.\n"
        }
        
        if timerLabel.text == "" {
            errorMsg += "-Must Provide a Time.\n"
        }

        if subjectPickedLabel.text != "" && taskPickedLabel.text != "" && timerLabel.text != "" {
        
            countDown = timeInterval
        
            if isTimerRunning == false {
            
                // create a alert action to let user confirm starting the focus session
                let startAlert = UIAlertController(title: "Are you Ready?", message: "During the Focus Session you are expected to not use your phone at all. \n\nNavigation to other sections of the app will also be disabled during the session. \n\nPlease place your phone and press Begin.", preferredStyle: .alert)
                
                startAlert.addAction(UIAlertAction(title: "Begin", style: .default) { (action) -> Void in
                    
                    // Session Began
                    self.runTimer()
                    self.databaseController!.setFocusSession(active: true)
                    self.databaseController!.setTimerRunning(active: true)
                    
                    // Disable navigation to other tab bar controllers
                    self.tabBarController!.tabBar.items!.forEach{ $0.isEnabled = false }
                    
                    self.beginSession.setTitle("", for: .normal)
                    self.beginSession.backgroundColor = self.pinkColor
                    self.pauseSession.backgroundColor = self.greyColor
                    self.beginSession.isEnabled = false
                    
                    // disable text fields during this duration
                    self.subjectPickedLabel.isEnabled = false
                    self.taskPickedLabel.isEnabled = false
                    self.timerLabel.isEnabled = false
                    
                    // Phone motion Sensor tracking enabled
                    // During this session, Alerts will be issued to the user if procrastination
                    self.startMotionSensor()

                    // If focus session done successfuly, then issue good streak
                    
                })
                
                startAlert.addAction(UIAlertAction(title: "Not Yet", style: .cancel))
                self.present(startAlert, animated: true, completion: nil)
                }
            }
    }
    
    // starts the motion sensor
    // Vibrations and alerts are played if movement is detected
    func startMotionSensor() {
        
        print("Initializing Motion Manager Sensor")
        motionManager = CMMotionManager()
        motionManager!.deviceMotionUpdateInterval = 0.5
        motionManager!.startDeviceMotionUpdates(to: OperationQueue.main) { (data, error) in
            
            guard data != nil else {
                print("Error occured: \(String(describing: error))")
                return
            }
            
            // Request user to place phone screen down to turn off the display
            UIDevice.current.isProximityMonitoringEnabled = true
            
            // App will run constantly and not go to sleep during the focus session
            UIApplication.shared.isIdleTimerDisabled = true
            
            // Dim the screen when session begins
            UIScreen.main.brightness = 0.5
            
            let xValue = round(data!.attitude.pitch)
            let yValue = round(data!.attitude.roll)
            let zValue = round(data!.attitude.yaw)
        

            if xValue != 0 || yValue != 0 || zValue != 0 {
                self.violation += 1

                // play vibration on phone
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                
                if self.violation < 20 {
                
                    // Annoy the user with alerts
                    AudioServicesPlayAlertSound(SystemSoundID(1005))
                    self.displayMessage(title: "Procrastination Detected", message: "Stop Touching your phone!!!")
                }
            }

            // Focus session failed if motion detected for 20 times in total
            if self.violation == 20 {
                
                // reset violation count
                self.violation = 0
                
                self.databaseController!.setFocusSession(active: false)
                self.databaseController!.setTimerRunning(active: false)
                
                // stop device motion
                self.motionManager?.stopDeviceMotionUpdates()
                
                // dismiss the current message to display failed message
                self.dismiss(animated: true) { () -> Void in
                    self.displayMessage(title: "Failed", message: "You have failed your Focus Session. Good Luck next time!")
                }
                
                // enable navigation to other tab bar controllers
                self.tabBarController!.tabBar.items!.forEach{ $0.isEnabled = true }
                
                self.isTimerRunning = false
                self.resumeTapped = false
                self.timerLabel.text = self.timeString(time: TimeInterval(self.timeInterval))
                self.beginSession.isEnabled = true
                self.beginSession.setTitle("Begin Session", for: .normal)
                self.beginSession.backgroundColor = self.greyColor
                self.pauseSession.backgroundColor = self.pinkColor
                self.pauseSession.isEnabled = false

                self.pauseSession.setTitle("", for: .normal)
                self.timer.invalidate()
                self.motionManager?.stopDeviceMotionUpdates()
                
                // proximity display back to normal
                UIDevice.current.isProximityMonitoringEnabled = false
                
                // display idle back to normal
                UIApplication.shared.isIdleTimerDisabled = false
                
                UIScreen.main.brightness = self.originalBrightness
                
                // Record the session's success and mark it down
                let success = self.databaseController!.getFocusSession()
                
                // re-enable the text fields
                self.subjectPickedLabel.isEnabled = true
                self.taskPickedLabel.isEnabled = true
                self.timerLabel.isEnabled = true
                
                // record the failed session to firebase
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM-dd-yyyy"
                let dateString = dateFormatter.string(from: Date())
                
                self.databaseController?.updateFocusSessionCompletion(date: dateString, success: success, focusTime: self.timeInterval)
            }
        }
    }
    
    // Function which displays alerts
    func displayMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default) { (UIAlertAction) -> Void in
        })
        
        // present only if no messages displayed
        if presentedViewController == nil {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
