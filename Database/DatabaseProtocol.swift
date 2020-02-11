//
//  DatabaseProtocol.swift
//  SaveMyTime
//  This class defines the functions and listeners required for the app to work
//
//  Created by Terence Ng on 6/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.


import Foundation
import UIKit

enum DatabaseChange {
    case add
    case remove
    case update
}

enum ListenerType {
    case incompletetask
    case completetask
    case subject
    case all

}

// Define a Listener protocol which listener classes will inherit
protocol DatabaseListener: AnyObject {
    var listenerType: ListenerType {get set}
    func onIncompleteTaskListChange(change: DatabaseChange, tasks: [Task])
    func onCompleteTaskListChange(change: DatabaseChange, tasks: [Task])
    func onSubjectListChange(change: DatabaseChange, subjects: [Subject])
    
}

// Define a protocol for database operations - storing user task data & user profile data
protocol DatabaseProtocol: AnyObject {
    
    func addNewTask(taskTitle: String, taskDesc: String, dueDate: String, taskSubject: String)
    
    func clearAllData()
    
    func getCompleteTasks(taskList: [Task]) -> [Task]
    
    func getIncompleteTasks(taskList: [Task]) -> [Task]

    func setAsCompleted(task: Task)
    
    func setUserSession(sessionID: String)
    
    func downloadProfile(handler: @escaping (_ Profile: [String : Any]?) -> Void)
    
    func deleteTask(task: Task)
    
    func deleteUserProfile(handler: @escaping (_ bool: Bool?) -> Void)
    
    func uploadProfilePicture(image: UIImage)
    
    func downloadProfilePicture(handler:@escaping (_ image:UIImage?) -> Void)

    func saveProfile(username: String, firstName: String, lastName: String, password: String, email: String)
    
    func addSubject(subjectName: String, subjectCode: String) -> Subject
    
    func updateSubject(subject: Subject)
    
    func deleteSubject(subject: Subject)
    
    func updateTask(task: Task)
    
    func deleteTaskWithSubjectID(subjectID: String)
    
    func getTasksWithSubjectID(subjectID: String) -> [Task]
    
    func updateTaskProgress(percentValue: Int, task: Task) -> Task
    
    func getSubjectDescfromID(subjectID: String, handler: @escaping (_ outputString: String?) -> Void)
    
    func getFocussedTime(date: String, handler: @escaping (_ focusTime: Int?) -> Void)
    
    func updateFocusSessionCompletion(date: String, success: Bool, focusTime: Int)
    
    func getAllSubjects() -> [Subject]
    
    func determineTaskNotifications()
    
    func determineProcrastinationNotifications()
    
    func setFocusSession(active: Bool)
    
    func getFocusSession() -> Bool
    
    func sortTaskList(taskList: [Task]) -> [[Task]]
    
    func getUserStatistics(handler: @escaping (_ totalSession: Int?, _ sessionSuccessRate: Int?, _ totalFailedSession: Int?, _ longestFocusTimeInDay: Int?, _ longestDay: Int?) -> Void)
    
    func removeAlarm()
    
    func setTimerRunning(active: Bool)
    
    func getTimerRunning() -> Bool

    
    //Attach listeners to tableView classes which need to update their tables whenever changes are made
    func addListener(listener: DatabaseListener)
    
    func removeListener(listener: DatabaseListener)
}
