//
//  MainPageViewController.swift
//  SaveMyTime
//
//  Created by Terence Ng on 5/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//


// This is the home screen of the app

import UIKit
import FirebaseAuth

class MainFocusPageViewController: UIViewController {
    
    var currentUser = Auth.auth().currentUser

    weak var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the database controller once from the App Delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController
        
        // Retrieve the user's profile data for display

        // Remove the back button as this is the main page
        self.navigationItem.setHidesBackButton(true, animated: true)

        // Do any additional setup after loading the view.
    }
    
    
    
    


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        
//        if segue.identifier == "toProfilePage" {
//
//
//            let destination = segue.destination as! UserProfileViewController
//
//        }
//    }


}
