//
//  AuthViewController.swift
//  SaveMyTime
//
//  Created by Terence Ng on 14/5/19.
//  This class deals with user login and authentication.

//  This Class will be instantiated as the initial root view controller if the user has not
//  been authenticated.
//  If the user is authenticated, then a segue will be performed to the app's main page automatically.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class AuthViewController: UIViewController, GIDSignInUIDelegate {

    weak var databaseController: DatabaseProtocol?
    @IBOutlet weak var defaultPicture: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the database controller once from the App Delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController
        
        GIDSignIn.sharedInstance()?.uiDelegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // If user is already authenticated, then perform segue to main page
        if Auth.auth().currentUser != nil {
            
            databaseController?.setUserSession(sessionID: Auth.auth().currentUser!.uid)
            self.performSegue(withIdentifier: "toMainPage", sender: nil)
        }
    }
    
    
    // It has been decided to delay Google authentication
    // for pursuit of more important functionality first
//    @IBAction func googleSignIn(_ sender: Any) {
//        GIDSignIn.sharedInstance()?.signIn()
//    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
