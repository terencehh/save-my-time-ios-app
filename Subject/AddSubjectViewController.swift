//
//  AddSubjectViewController.swift
//  SaveMyTime
//  This class handles adding subject functionality
//  Standard operations apply such as validation, clear button, and add subject button.
//
//  Created by Terence Ng on 24/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit

class AddSubjectViewController: UIViewController, UITextFieldDelegate {
    
    // get reference to database controller
    weak var databaseController: DatabaseProtocol?

    // get reference to text field
    @IBOutlet weak var subjectCodeTextField: UITextField!
    @IBOutlet weak var subjectNameTextField: UITextField!
    
    // represent whether a task was added successfully
    var success: Bool = false
    
    // get a reference to the bottom constraint to push view up when keyboard appears
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the database controller once from the App Delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController
        
        // Implement observers which push views up when keyboard appears
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // make sure the text field implements the delegate to 'return' after keyboard return press
        subjectNameTextField.delegate = self
        subjectCodeTextField.delegate = self
        
        // Configure gesture which closes keyboard on taps in the view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(gestureRecognizer:)))
        view.addGestureRecognizer(tapGesture)

        // create underlined line for input textfield
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(origin: CGPoint(x: 0, y: subjectCodeTextField.frame.height-10), size: CGSize(width: subjectCodeTextField.frame.width, height: 0.5))
        bottomLine.backgroundColor = UIColor.white.cgColor
        subjectCodeTextField.borderStyle = UITextField.BorderStyle.none
        subjectCodeTextField.layer.addSublayer(bottomLine)
        
        // create underlined line for input textfield
        let bottomLine1 = CALayer()
        bottomLine1.frame = CGRect(origin: CGPoint(x: 0, y: subjectNameTextField.frame.height-10), size: CGSize(width: subjectNameTextField.frame.width, height: 0.5))
        bottomLine1.backgroundColor = UIColor.white.cgColor
        subjectNameTextField.borderStyle = UITextField.BorderStyle.none
        subjectNameTextField.layer.addSublayer(bottomLine1)
        
    }
    // ends keyboard editing
    @objc func viewTapped(gestureRecognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    // pushes view content up on keyboard show
    @objc func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        UIView.animate(withDuration: 0.1) { () -> Void in
            self.bottomConstraint.constant = keyboardFrame.size.height
        }
    }
    
    // restore bottom constraint back to normal when keyboard dismissed
    @objc func keyboardWillHide(notification: NSNotification) {
        
        UIView.animate(withDuration: 0.1) { () -> Void in
            self.bottomConstraint.constant = 155
        }
    }
    
    // Adds users subject into Firebase
    // Performs user-validation first before doing so
    @IBAction func saveSubjectButton(_ sender: Any) {
        
        // perform validation of input fields before saving data
        success = false
        
        if subjectNameTextField.text == "" {
            displayMessage(title: "Error", message: "Please enter a subject Name.")
            return
        }
        
        if subjectCodeTextField.text == "" {
            displayMessage(title: "Error", message: "Please enter a Subject Code.")
            return            
        }
        
        let subjectName = subjectNameTextField.text!
        let subjectCode = subjectCodeTextField.text!
        
        success = true

        let _ = databaseController!.addSubject(subjectName: subjectName, subjectCode: subjectCode)
        displayMessage(title: "Success!", message: "Subject has been successfully Added.")
    }
    
    @IBAction func clearAll(_ sender: Any) {
        subjectCodeTextField.text = ""
        subjectNameTextField.text = ""
    }
    
    // Function which displays alerts
    func displayMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default) { (UIAlertAction) -> Void in
            
            // pop view controller
            if self.success == true {
                CATransaction.begin()
                self.navigationController?.popViewController(animated: true)
                CATransaction.commit()
            }
        })
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // Dismiss the keyboard when the return key is tapped
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}
