//
//  FirebaseController.swift
//  SaveMyTime
//  This class handles all database functionality required for the app
//  Small data is stored in Firebase Firestore
//  Image data isstored in Firebase Storage
//
//  Created by Terence Ng on 6/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import UserNotifications
import FirebaseFirestore
import AVFoundation
import MediaPlayer

// the firebase controller for the app
// If this class is instantiated, it means that the user has signed in successfully and is authenticated.

class FirebaseController: NSObject, DatabaseProtocol {
    
    var listeners = MulticastDelegate<DatabaseListener>()
    
    // Retrieve reference to app delegate notification and notification center
    var notifications: Notification
    var notificationCenter: UNUserNotificationCenter
    
    // Audio player for issuing repeating alarms
    var audioPlayer: AVAudioPlayer?
    
    // Auth Controller
    var authController: Auth
    
    // The database
    var database: Firestore
    
    // the userID session after authentication - only appears after user has authenticated
    var userID: String?
    
    // the default root directory for users
    var userReference: DocumentReference?
    
    // the directory for user's tasks
    var taskRef: CollectionReference?
    
    // the directory for user's profile data
    var profileRef: CollectionReference?
    
    // the directory for user's subjects
    var subjectRef: CollectionReference?
    
    // the directory for user's procrastination stats
    var statisticRef: CollectionReference?
    
    // default storage directory for large files e.g. images
    var storageReference = Storage.storage().reference()
    
    var taskList: [Task]
    var subjectList: [Subject]
    
    // Determine if the user is currently in a focus session
    var activeSession: Bool = false
    
    // Determine if the timer is running
    var timerRunning: Bool = false
    
    override init() {
        
        authController = Auth.auth()
        database = Firestore.firestore()
        
        // Local storage for tasks
        taskList = [Task]()

        //Local storage for subjects
        subjectList = [Subject]()
        
        // get the notification class from AppDelegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.notifications = appDelegate.notification!
        self.notificationCenter = appDelegate.notificationCenter
        
        super.init()
    }
    
    // this function clears all local storage when user signs out
    func clearAllData() {
        taskList.removeAll()
        subjectList.removeAll()
    }
    
    func setUserSession(sessionID: String) {
        
        // set the user's ID, private directories, and profile data
        
        userID = authController.currentUser?.uid
        userReference = database.collection("user").document("\(userID!)")
        
        // Important references are defined here
        taskRef = userReference!.collection("task")
        profileRef = userReference!.collection("profile")
        subjectRef = userReference!.collection("subject")
        statisticRef = userReference!.collection("statistics")
        
        // once authenticated, attach listeners to firebase firestore
        setUpListeners()
        
    }
    
    // This function determines which notifications to send by checking the user tasks due dates
    // How notifications are scheduled depends on the urgency of the task to complete
    
    // Logic Assumptions:
    // Overdue Tasks results in repeating notifications every 1 hour once app enters background
    // Priority Tasks results in repeating notifications every 1 day once app enters background
    func determineTaskNotifications() {
        
        // determine how notification should need to be set up
        var sortedList: [[Task]] = sortTaskList(taskList: getIncompleteTasks(taskList: taskList))

        let overDueTasks = sortedList[0]
        let priorityTasks = sortedList[1]
        
        if overDueTasks.count > 0 {
            
            // FOR DEMONSTRATION PURPOSES, set notification occurence to repeat every 70 seconds
            print("Scheduling Overdue Tasks Notifications")
            notifications.scheduleNotification(message: "You have Urgent Tasks due, Get Working Now!", type: "Overdue", timeOccurence: 3600)
        }
        
        else if priorityTasks.count > 0 {
            
            // FOR DEMONSTRATION PURPOSES, set notification occurence to repeat every 80 seconds
            print("Scheduling Priority Tasks Notifications")
            notifications.scheduleNotification(message: "You have Priority Tasks due, Start Working Soon!", type: "Priority", timeOccurence: 86400)
        }
    }
    
    // This function sends notifications & Alarms to the user if the app enters the background (User is Procrastinating)
    // while a focus Session is still on-going
    
    // Feature Restrictions
    // The minimum notification repeats I can specify when a user enters the background and procrastinates
    // is 1 minute
    func determineProcrastinationNotifications() {
        
        if activeSession == true {
            print("Scheduling Procrastination Notifications")
            notifications.scheduleNotification(message: "Stop Procrastinating!!", type: "Procrastination", timeOccurence: 60)
            
            // schedule an alarm, loops infinitely until user goes back to the app
            do {
                // duckothers mutes external sounds so that this sound is larger
                // defaultToSpeaker makes volume go louder by being at speaker
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: [.duckOthers, .defaultToSpeaker])
                try AVAudioSession.sharedInstance().setActive(true)
                UIApplication.shared.beginReceivingRemoteControlEvents()
            } catch {
                print("Audio Session error: \(error)")
            }

            // configure alarm sound
            let sound = Bundle.main.path(forResource: "Alarm", ofType: "mp3")
            
            do {
                try audioPlayer = AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
            } catch {
                print(error)
            }
            
            // MPVolumeView allows us to adjust the iphone volume programmatically
            let volumeView = MPVolumeView()
            volumeView.volumeSlider.value = 1.0
            
            // Loops sound infinitely
            audioPlayer?.numberOfLoops = Int.max
            audioPlayer?.play()
        }
    }
    // stops the alarm
    // this occurs when the user returns to the app
    func removeAlarm() {
        if audioPlayer?.isPlaying == true {
            audioPlayer?.stop()
        }
    }
    
    // sets focus session
    func setFocusSession(active: Bool) {
        activeSession = active
    }
    // gets focus session
    func getFocusSession() -> Bool {
        return activeSession
    }
    
    func setTimerRunning(active: Bool) {
        timerRunning = active
    }
    
    func getTimerRunning() -> Bool {
        return timerRunning
    }
    
    // setup listeners for specific references in the user's firebase directory
    func setUpListeners() {
        
        subjectRef?.addSnapshotListener { querySnapshot, error in
            guard(querySnapshot?.documents) != nil else {
                print("Error fetching documents: \(error!)")
                return
            }
            self.parseSubjectsSnapshot(snapshot: querySnapshot!)
        }
        
        taskRef?.addSnapshotListener { querySnapshot, error in
            guard(querySnapshot?.documents) != nil else {
                print("Error fetching documents: \(error!)")
                return
            }
            self.parseTaskSnapshot(snapshot: querySnapshot!)
        }
    }
    
    // parses incoming subjects
    func parseSubjectsSnapshot(snapshot: QuerySnapshot) {
        print("Parsing Subjects")
        snapshot.documentChanges.forEach { change in
            let documentRef = change.document.documentID
            
            let subjectCode = change.document.data()["subjectCode"] as! String
            let subjectName = change.document.data()["subjectName"] as! String
            
            switch (change.type) {
                
            case .added:
                
                print("New Subject: \(change.document.data())")
                let newSubject = Subject(id: documentRef, subjectCode: subjectCode, subjectName: subjectName)
                subjectList.append(newSubject)
                break
                
            case .modified:
                
                print("Updated Subject: \(change.document.data())")
                let index = getSubjectByID(reference: documentRef)!
                
                subjectList[index].id = documentRef
                subjectList[index].subjectCode = subjectCode
                subjectList[index].subjectName = subjectName
                break
                
            case .removed:
                
                print("Removed Subject: \(change.document.data())")
                if let index = getSubjectByID(reference: documentRef) {
                    subjectList.remove(at: index)
                    break
                }
            }
        }
        
        listeners.invoke { listener in
            if listener.listenerType == ListenerType.subject || listener.listenerType == ListenerType.all {
                listener.onSubjectListChange(change: .update, subjects: subjectList)
            }
        }
    }
    
    // retrieve subjects based on a specified iD
    func getSubjectByID(reference: String) -> Int? {
        for subject in subjectList {
            if(subject.id == reference) {
                return subjectList.firstIndex(of: subject)
            }
        }
        return nil
    }

    // parse tasks
    func parseTaskSnapshot(snapshot: QuerySnapshot) {
        print("Parsing Tasks")
        snapshot.documentChanges.forEach { change in
            let documentRef = change.document.documentID
            let taskTitle = change.document.data()["taskTitle"] as! String
            let taskDesc = change.document.data()["taskDesc"] as! String
            let dueDate = change.document.data()["dueDate"] as! String
            let taskSubjectID = change.document.data()["taskSubjectID"] as! String
            let taskPercentage = change.document.data()["taskPercentage"] as! Int
            let taskCompleted = change.document.data()["taskCompleted"] as! Bool
            
            switch (change.type) {
                
            case .added:
                
                print("New Task: \(change.document.data())")
                let newTask = Task(taskid: documentRef, taskTitle: taskTitle, taskDesc: taskDesc, dueDate: dueDate, taskSubjectID: taskSubjectID, taskPercentage: taskPercentage, taskCompleted: taskCompleted )
                taskList.append(newTask)
                break
                
            case .modified:
                
                print("Updated Task: \(change.document.data())")
                let index = getTaskIndexByID(reference: documentRef)!
                taskList[index].taskTitle = taskTitle
                taskList[index].taskDesc = taskDesc
                taskList[index].dueDate = dueDate
                taskList[index].taskSubjectID = taskSubjectID
                taskList[index].taskPercentage = taskPercentage
                taskList[index].taskCompleted = taskCompleted
                
                break
                
            case .removed:
                
                print("Removed Task: \(change.document.data())")
                if let index = getTaskIndexByID(reference: documentRef) {
                    taskList.remove(at: index)
                    break
                }
            }
        }
        
        listeners.invoke { (listener) in
            // split complete and Incomplete
            
            if listener.listenerType == ListenerType.incompletetask {
                listener.onIncompleteTaskListChange(change: .update, tasks: getIncompleteTasks(taskList: taskList))
            }
            else if listener.listenerType == ListenerType.completetask {
                listener.onCompleteTaskListChange(change: .update, tasks: getCompleteTasks(taskList: taskList))
            }
        }
    }
    
    // retrieve task based on a ID
    func getTaskIndexByID(reference: String) -> Int? {
        for task in taskList {
            if (task.taskid == reference) {
                return taskList.firstIndex(of: task)
            }
        }
        
        return nil
    }
    
    // retrieve completed tasks
    func getCompleteTasks(taskList: [Task]) -> [Task] {
        var outputList = [Task]()
        for task in taskList {
            if task.taskCompleted == true {
                outputList.append(task)
            }
        }
        return outputList
    }
    
    // retrieve incomplete tasks
    func getIncompleteTasks(taskList: [Task]) -> [Task] {
        var outputList = [Task]()
        for task in taskList {
            if task.taskCompleted == false {
                outputList.append(task)
            }
        }
        return outputList
    }
    
    // add a new task
    func addNewTask(taskTitle: String, taskDesc: String, dueDate: String, taskSubject: String) {
        
        taskRef!.addDocument(data: ["taskTitle": taskTitle, "taskDesc": taskDesc, "dueDate": dueDate, "taskSubjectID": taskSubject, "taskPercentage": 0, "taskCompleted": false])
    }
    
    func updateTask(task: Task) {
        
        taskRef?.document(task.taskid).setData(["taskTitle": task.taskTitle, "taskDesc": task.taskDesc, "dueDate": task.dueDate, "taskSubjectID": task.taskSubjectID, "taskPercentage": task.taskPercentage, "taskCompleted": task.taskCompleted])
    }
    

    func setAsCompleted(task: Task) {
        
        let documentRef = task.taskid

        if let index = getTaskIndexByID(reference: documentRef) {
            taskList[index].taskCompleted = true
        }
    }
    
    // This function uploads the jpeg picture onto the storage reference
    // of firebase
    func uploadProfilePicture(image: UIImage) {
        
        
        guard let userID = authController.currentUser?.uid else {
            print("Need to be signed in first")
            return
        }

        var imageData = Data()
        imageData = image.jpegData(compressionQuality: 0.8)!
        
        let imageRef = storageReference.child("\(userID)/profileImage")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpg"
        
        imageRef.putData(imageData, metadata: metadata) { metaData, error in
            
            if error == nil {
                
                imageRef.downloadURL { url, error in
                    guard url != nil else {
                        print("Download URL not found")
                        return
                    }
                    print("Image uploaded to Firebase")
                    // success!
                }
            }
        }
    }
    
    
    // This function should add a new document profile for first-time users
    func saveProfile(username: String, firstName: String, lastName: String, password: String, email: String) {
        
        let userObject = [
            "username"  : username,
            "firstName" : firstName,
            "lastName"  : lastName,
            "password"  : password,
            "email"     : email,
            
            ] as [String : Any]
        
        profileRef?.document("profileData").setData(userObject)
        }
    
    // downloads the user profile for display
    func downloadProfile(handler: @escaping (_ Profile: [String : Any]?) -> Void) {
        
        let profileLocation = profileRef!.document("profileData")

        profileLocation.getDocument { (document, error) in
            if let document = document, document.exists {
                // document data retrieved, return it to handler
                handler(document.data())
                
            } else {
                print("Document does not exist")
            }
        }
    }
    
    // sorts the taskList based on 3 sections
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
    
    // downloads user profile picture and store it in firebase storage
    func downloadProfilePicture(handler: @escaping (_ image:UIImage?) -> Void) {
        
        let imageRef = storageReference.child("\(userID!)/profileImage")
        
        // download in memory with maximum allowed size of 1MB
        imageRef.getData(maxSize: 10 * 1024 * 1024) { (data, error) in
            if let error = error {
                // error occured
                print(error.localizedDescription)
            }
            else {
                if let data = data {
                    // data for image is downloaded
                    handler(UIImage(data: data))
                }
            }
        }
    }
    
    // this function deletes the user - note it returns early after deleting the user, rather than
    // after deleting everything from the user. This ensures faster user interface transition.
    func deleteUserProfile(handler: @escaping (_ bool: Bool?) -> Void) {
        
        // Delete the user from Auth
        let user = Auth.auth().currentUser
        
        user!.delete() { error in
        if let error = error {
            print("Error Deleting user Profile: \(error)")
        }
        else {
            print("User successfully deleted")
            handler(true)
            }
            
        }
        
        // delete user's profile data
        let profileLocation = profileRef!.document("profileData")

        profileLocation.delete() { error in
            if let error = error {
                print("Error removing document: \(error)")
            }

            else {
                print("User profile data successfully deleted")
            }
        }
        
        // ASSUME WE KEEP user's subject & Tasks Data for reasons: If user signs up in the future - he will keep his current subject and tasks

        // delete user's profile picture located in firebase Storage
        
        let imageRef = storageReference.child("\(userID!)/profileImage")
        
        imageRef.delete() { error in
            if let error = error {
                print("Error removing user's profile picture: \(error)")
            }
            else {
                print("User profile picture successfully deleted")
            }
        }
        
    }
    
    // adds subject by adding a new document in subject firebase collection
    func addSubject(subjectName: String, subjectCode: String) -> Subject {
        
        let id = subjectRef?.addDocument(data: ["subjectCode" : subjectCode, "subjectName" : subjectName])
        
        let subject = Subject(id: id!.documentID, subjectCode: subjectCode, subjectName: subjectName)
        
        return subject
    }
    
    // delete subject based on a given subject
    func deleteSubject(subject: Subject) {
        
        deleteTaskWithSubjectID(subjectID: subject.id)
        
        subjectRef?.document(subject.id).delete()
    }
    
    // updates subject based on a given subject
    func updateSubject(subject: Subject) {
        
        subjectRef?.document(subject.id).setData(["subjectCode" : subject.subjectCode, "subjectName" : subject.subjectName])
    }
    
    // updates task progress, if completed, set completed field to true in firebase
    func updateTaskProgress(percentValue: Int, task: Task) -> Task {
        
        if percentValue == Int(100.0) {
            taskRef?.document(task.taskid).setData(["dueDate" : task.dueDate, "taskCompleted" : true, "taskDesc" : task.taskDesc, "taskPercentage" : Int(percentValue), "taskSubjectID" : task.taskSubjectID, "taskTitle" : task.taskTitle])
            task.taskPercentage = percentValue
            task.taskCompleted = true
            
        } else {
            taskRef?.document(task.taskid).setData(["dueDate" : task.dueDate, "taskCompleted" : false, "taskDesc" : task.taskDesc, "taskPercentage" : Int(percentValue), "taskSubjectID" : task.taskSubjectID, "taskTitle" : task.taskTitle])
            task.taskPercentage = percentValue
        }
        
        return task
    }
    
    // delete task based on a given task
    func deleteTask(task: Task){
        taskRef!.document(task.taskid).delete()
    }
    
    // retrieve all subjects
    func getAllSubjects() -> [Subject] {
        return subjectList
    }
    
    // this function deletes all tasks which have subjectID as the one about to be deleted
    // should only be called after deleteSubject()
    func deleteTaskWithSubjectID(subjectID: String) {
        
        taskRef!.whereField("taskSubjectID", isEqualTo: subjectID).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    document.reference.delete()
                }
            }
        }
    }
    
    // Retrieves a list of tasks which contains a specific subject ID
    func getTasksWithSubjectID(subjectID: String) -> [Task] {
        
        var outputList = [Task]()
        
        for task in taskList {
            if task.taskSubjectID == subjectID {
                outputList.append(task)
            }
        }
        print(outputList)
        return outputList
    }
    
    // retrieves the user's focus time for a specified day
    func getFocussedTime(date: String, handler: @escaping (_ focusTime: Int?) -> Void) {
        
        var time: Int = 0
        
        let docRef = statisticRef?.document(date)
        docRef!.getDocument { (document, error) in
            if let document = document, document.exists {
                
                time = document.get("focusedTime") as! Int
                handler(time)
            } else {
                handler(time)
            }
        }

    }
    
    // updates the user's focus session when they have completed one
    func updateFocusSessionCompletion(date: String, success: Bool, focusTime: Int) {
        
        let docRef = statisticRef?.document(date)
        var totalSession: Int = 0
        var sessionSuccessRate: Int = 100
        var failedSession: Int = 0
        
        // this stores the time in seconds the user has worked for
        var focusedTime: Int = 0
        
        // check if document exists
        docRef!.getDocument { (document, error) in
            if let document = document, document.exists {
                
                // Retrieve current data
                totalSession = document.get("totalSession") as! Int
                failedSession = document.get("failedSession") as! Int
                sessionSuccessRate = document.get("sessionSuccessRate") as! Int
                focusedTime = document.get("focusedTime") as! Int
                
                
            } else {
                // Document does not exist
                // set initial values
                docRef?.setData(["totalSession" : totalSession, "failedSession" : failedSession, "sessionSuccessRate" : sessionSuccessRate, "focusedTime" : focusedTime])
            }
            
            totalSession += 1
            if success == false {
                failedSession += 1
            } else {
                focusedTime += focusTime
            }
            if failedSession == 0 {
                sessionSuccessRate = 100
            } else {
                sessionSuccessRate = Int((Double(totalSession - failedSession) / Double(totalSession)) * 100)
            }
            
            
            docRef?.setData(["totalSession" : totalSession, "failedSession" : failedSession, "sessionSuccessRate" : sessionSuccessRate, "focusedTime" : focusedTime])
        }
    }
    
    // get the subject description based on a given subject
    func getSubjectDescfromID(subjectID: String, handler: @escaping (_ outputString: String?) -> Void) {
        
        subjectRef?.document(subjectID).getDocument { (document, error) in
            if let document = document, document.exists {
                
                var outputString = document.data()!["subjectCode"] as! String + " "
                outputString += document.data()!["subjectName"] as! String
                handler(outputString)
            }
        }
    }
    
    // This function retrieves User Statistics to be displayed into the Statistics Class
    // It does this by going through the day documents for the user's statistics firebase directory
    func getUserStatistics(handler: @escaping (_ totalSession: Int?, _ sessionSuccessRate: Int?, _ totalFailedSession: Int?, _ longestFocusTimeInDay: Int?, _ longestDay: Int?) -> Void) {
        
        var iterator: Int = 0
        var longestDay: Int = 0
        var totalFocusTime: Int = 0
        var longestFocusDayTime: Int = 0
        var sessionSuccessRate: Int = 100
        var totalSessions: Int = 0
        var totalFailedSessions: Int = 0
        var averageFocusTime: Int = 0
        
        statisticRef?.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    
                    totalSessions += document.get("totalSession") as! Int
                    totalFailedSessions += document.get("failedSession") as! Int
                    
                    if document.get("focusedTime") as! Int > longestFocusDayTime {
                        longestFocusDayTime = document.get("focusedTime") as! Int
                    }
                    
                    totalFocusTime += document.get("focusedTime") as! Int
                    
                    if document.get("failedSession") as! Int == 0 {
                        iterator += 1
                    } else {
                        if iterator > longestDay {
                            longestDay = iterator
                        }
                        iterator = 0
                    }
                }
                
                averageFocusTime = Int(Double(totalFocusTime)/Double(totalSessions - totalFailedSessions))
                
                if iterator > longestDay {
                    longestDay = iterator
                }
                
                if totalFailedSessions == 0 || totalSessions == 0 {
                    sessionSuccessRate = 100
                } else {
                    sessionSuccessRate = Int((Double(totalSessions - totalFailedSessions) / Double(totalSessions)) * 100)
                }
            }
            handler(totalSessions, sessionSuccessRate, averageFocusTime, longestFocusDayTime, longestDay)
        }
        
    }
    
    // adds listeners
    func addListener(listener: DatabaseListener) {
        listeners.addDelegate(listener)
        
        if listener.listenerType == ListenerType.incompletetask || listener.listenerType == ListenerType.all {
            listener.onIncompleteTaskListChange(change: .update, tasks: getIncompleteTasks(taskList: taskList))
        }
        
        if listener.listenerType == ListenerType.completetask || listener.listenerType == ListenerType.all {
            listener.onCompleteTaskListChange(change: .update, tasks: getCompleteTasks(taskList: taskList))
        }
        
        if listener.listenerType == ListenerType.subject || listener.listenerType == ListenerType.all {
            listener.onSubjectListChange(change: .update, subjects: subjectList)
        }
        
    }
    
    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }
}

// Extension to MPVolumeView to programmatically set iphone's volume
// Taken by Medium Article http://andrewmarinov.com/building-an-alarm-app-on-ios/
private extension MPVolumeView {
    var volumeSlider: UISlider {
        self.showsRouteButton = false
        self.showsVolumeSlider = false
        self.isHidden = true
        var slider = UISlider()
        for subview in self.subviews {
            if subview.isKind(of: UISlider.self) {
                slider = subview as! UISlider
                slider.isContinuous = false
                (subview as! UISlider).value = 1
                return slider
            }
        }
        return slider
    }
}



