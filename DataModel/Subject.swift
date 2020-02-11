//
//  Subject.swift
//  SaveMyTime
//  This class represents a subject in SaveMyTime
//
//  Created by Terence Ng on 25/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import Foundation

class Subject: NSObject {
    var subjectCode: String
    var subjectName: String
    var id: String
    
    init(id: String, subjectCode: String, subjectName: String) {
        
        self.id = id
        self.subjectCode = subjectCode
        self.subjectName = subjectName
    }
}
