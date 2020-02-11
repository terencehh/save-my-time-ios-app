//
//  UserSettingsViewController.swift
//  SaveMyTime
//  This class handles navigations for anything regarding user settings
//  Users will be able to view their completed tasks, manage their subjects, view their account info, and sign-out

//  Created by Terence Ng on 25/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit
import FirebaseAuth


class UserSettingsViewController: UIViewController {
    
    var currentUser = Auth.auth().currentUser
    
    weak var databaseController: DatabaseProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the database controller once from the App Delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController
        
        // Retrieve the user's profile data for display
        
//        // Remove the back button as this is the main page
//        self.navigationItem.setHidesBackButton(true, animated: true)
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func signOutPressed(_ sender: Any) {
        
        // clear local tables in the firebaseController before signing out
        databaseController!.clearAllData()
        
        try! Auth.auth().signOut()
        print("Signed out successfully")
        
        
        // Replace the storyboard and reset it to initial login page
        // Solution was taken at StackOverflow and altered by Terence Ng
        // https://stackoverflow.com/questions/37051676/change-mainviewcontroller-in-ios-with-swift-after-login
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "notLoggedIn")
//
//        let rootController = storyboard.instantiateViewController(withIdentifier: "notLoggedIn")
//        UIApplication.shared.keyWindow?.rootViewController = rootController
//        self.navigationController?.popToRootViewController(animated: true)
        
    }
}
