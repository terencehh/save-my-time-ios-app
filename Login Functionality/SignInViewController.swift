//
//  SignInViewController.swift
//  SaveMyTime
//
//  Created by Terence Ng on 5/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit
import FirebaseAuth

class SignInViewController: UIViewController, UITextFieldDelegate {

    // Get a reference to input fields
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    var handle: AuthStateDidChangeListenerHandle?
    
    // get a reference to app delegate's database controller
    weak var databaseController: DatabaseProtocol?
    
    // get a reference to bottom constraint
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // invoke a gesture recognizer on the view such that if tapped, disable editing
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(gestureRecognizer:)))
        view.addGestureRecognizer(tapGesture)
        
        // Get the database controller once from the App Delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController
        
        // Add observers which invokes a function pushing all view components up if the keyboard is shown
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // ensure text fields inherit their delegate for custom behaviours
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        // this ensures the view dismisses when user touches anywhere on the view controller
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        // create underlined line for input textfield
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(origin: CGPoint(x: 0, y: emailTextField.frame.height-10), size: CGSize(width: emailTextField.frame.width, height: 0.5))
        bottomLine.backgroundColor = UIColor.white.cgColor
        emailTextField.borderStyle = UITextField.BorderStyle.none
        emailTextField.layer.addSublayer(bottomLine)
        
        // create underlined line for input textfield
        let bottomLine1 = CALayer()
        bottomLine1.frame = CGRect(origin: CGPoint(x: 0, y: passwordTextField.frame.height-10), size: CGSize(width: passwordTextField.frame.width, height: 0.5))
        bottomLine1.backgroundColor = UIColor.white.cgColor
        passwordTextField.borderStyle = UITextField.BorderStyle.none
        passwordTextField.layer.addSublayer(bottomLine1)
        
        
        // Do any additional setup after loading the view.
    }
    
    // if invoked, end editing of the view
    @objc func viewTapped(gestureRecognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    // if invoked, push bottom constraint up so that keyboard does not hide components
    @objc func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        UIView.animate(withDuration: 0.1) { () -> Void in
            self.bottomConstraint.constant = keyboardFrame.size.height + 20
        }
    }
    
    // restore bottom constraint
    @objc func keyboardWillHide(notification: NSNotification) {
        
        UIView.animate(withDuration: 0.1) { () -> Void in
            self.bottomConstraint.constant = 100
        }
    }

    // Dismiss the keyboard when the return key is tapped
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    // Go back to root page
    @IBAction func backButton(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "notLoggedIn")
    }
    
    // Performs user sign-in
    // Contains validation and if successful, navigate to Main Page
    @IBAction func signInButton(_ sender: Any) {
        
        // TODO: Perform validation on the email and password
        
        if emailTextField.text == "" {
            displayMessage(title: "Error", message: "Please enter an email address")
            return
            
        }
        
        if passwordTextField.text == "" {
            displayMessage(title: "Error", message: "Please enter a password")
            return
        }
        
        let email = emailTextField.text!
        let password = passwordTextField.text!

        // Register user with Firebase
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            
            // Check that user is not nil
            if error == nil {
                
                // signed in
                self.databaseController?.setUserSession(sessionID: Auth.auth().currentUser!.uid)
                self.performSegue(withIdentifier: "toMainPage", sender: self)
            }
            else {
                // Error: check error and show message
                self.displayMessage(title: "Error", message: error!.localizedDescription)
            }
    }

}
    // Function which displays UIAlerts
    func displayMessage(title: String, message: String) {
        // Setup an alert to show user details about the Person
        // UIAlertController manages an alert instance
        let alertController = UIAlertController(title: title, message: message,
                                                preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style:
            UIAlertAction.Style.default,handler: nil))

    self.present(alertController, animated: true, completion: nil)
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
