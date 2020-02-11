//
//  CreateAccountViewController.swift
//  SaveMyTime
//
//  Created by Terence Ng on 5/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit
import FirebaseAuth

class SignUpViewController: UIViewController {
    
    var task: String!
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    

    
    @IBOutlet weak var buttonText: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if task == "Sign Up" {
            buttonText.setTitle("Sign Up", for: .normal)
        }
        
        else if task == "Sign In" {
            buttonText.setTitle("Sign In", for: .normal)
        }

        // Do any additional setup after loading the view.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Dismiss the keyboard when the view is tapped on
        emailTextField.resignFirstResponder()
        firstNameTextField.resignFirstResponder()
        lastNameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    

    @IBAction func signButtonTapped(_ sender: Any) {
        
        // TODO: Perform form validation on the email and password
        
        if let email = emailTextField.text, let pass = passwordTextField.text, let first = firstNameTextField, let last = lastNameTextField {
            
            // If signing in then sign in the user with Firebase
            
            if task == "Sign In" {
                
                Auth.auth().signIn(withEmail: email, password: pass, completion: { (user, error) in
                    
                     //check that user is not nil
                    if user != nil {
                        // User is found, go to home screen
                        self.performSegue(withIdentifier: "toMainPage", sender: self)
                    }
                    else {
                        // Error: check error and show message
                    }
                })
            }
                
            else {
                // Register user with Firebase
                Auth.auth().createUser(withEmail: email, password: pass, completion: { (user, error) in
                    
                    // Check that user is not nil
                    if user != nil {
                        // User is found, go to home screen
                        self.performSegue(withIdentifier: "toMainPage", sender: self)
                    }
                    else {
                        // Error: check error and show message
                    }
                })
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
