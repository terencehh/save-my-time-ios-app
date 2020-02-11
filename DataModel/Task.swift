//
//  Task.swift
//  SaveMyTime
//  This class represents a task in SaveMyTime
//
//  Created by Terence Ng on 13/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//


import Foundation


class Task: NSObject {
    var taskTitle: String
    var taskDesc: String
    var dueDate: String
    var taskSubjectID: String
    var taskPercentage: Int
    var taskid: String
    var taskCompleted: Bool
    
    init(taskid: String, taskTitle: String, taskDesc: String, dueDate: String, taskSubjectID: String, taskPercentage: Int, taskCompleted: Bool) {
        
        self.taskid = taskid
        self.taskTitle = taskTitle
        self.taskDesc = taskDesc
        self.dueDate = dueDate
        self.taskSubjectID = taskSubjectID
        self.taskPercentage = taskPercentage
        self.taskCompleted = taskCompleted
        
    }
}
