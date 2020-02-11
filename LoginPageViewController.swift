//
//  LoginPageViewController.swift
//  SaveMyTime
//
//  Created by Terence Ng on 6/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit
import FirebaseAuth
import GoogleSignIn

class AuthViewController: UIViewController, GIDSignInUIDelegate {


    
    var databaseController: DatabaseProtocol?
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBAction func googleSignInButton(_ sender: Any) {
        
        GIDSignIn.sharedInstance()?.signIn()

        self.performSegue(withIdentifier: "toMainPage", sender: self)

    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance()?.uiDelegate = self
        profileImageView.image = UIImage(named: "GOOD")

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Retrieve the current user logged in within the system to ensure
        // user does not have to always re-login again
        if Auth.auth().currentUser != nil {
            self.performSegue(withIdentifier: "toMainPage", sender: self)
        }
    }

    
    func displayMessage(title: String, message: String) {
        // Setup an alert to show user details about the Person
        // UIAlertController manages an alert instance
        let alertController = UIAlertController(title: title, message: message,
                                                preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style:
            UIAlertAction.Style.default,handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//
//
//        }
    
//         Get the new view controller using segue.destination.
//         Pass the selected object to the new view controller.
    }
    


