//
//  Profile.swift
//  SaveMyTime
//  This class represents a profile in SaveMyTime
//
//  Created by Terence Ng on 13/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import Foundation
import UIKit

class Profile: NSObject {
    
    var username: String
    var firstName: String
    var lastName: String
    var password: String
    var email: String
    
    init(username: String,firstName: String, lastName: String, password: String, email: String) {
        
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.password = password
        self.email = email
    }
}
