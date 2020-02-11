//
//  EditSubjectViewController.swift
//  SaveMyTime
//  This class handles editing subject functionality
//  Standard operations apply such as validation, clear button, save subject, and delete subject
//
//  Created by Terence Ng on 24/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit

class EditSubjectViewController: UIViewController, UITextFieldDelegate {
    
    // the subject passed from the subject list
    var passedSubject: Subject!
    
    // represents whether a operation has been successfully performed
    var success: Bool = false
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    weak var databaseController: DatabaseProtocol?
    
    
    @IBOutlet weak var subjectCodeLabel: UITextField!
    @IBOutlet weak var subjectNameLabel: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Get the database controller once from App Delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController
        
        // Implement observers which push view up when keyboard is shown
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        subjectNameLabel.delegate = self
        subjectCodeLabel.delegate = self
        
        subjectCodeLabel.text = passedSubject.subjectCode
        subjectNameLabel.text = passedSubject.subjectName
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(gestureRecognizer:)))
        view.addGestureRecognizer(tapGesture)
        
        // create underlined line for input textfield
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(origin: CGPoint(x: 0, y: subjectCodeLabel.frame.height-10), size: CGSize(width: subjectCodeLabel.frame.width, height: 0.5))
        bottomLine.backgroundColor = UIColor.white.cgColor
        subjectCodeLabel.borderStyle = UITextField.BorderStyle.none
        subjectCodeLabel.layer.addSublayer(bottomLine)
        
        // create underlined line for input textfield
        let bottomLine1 = CALayer()
        bottomLine1.frame = CGRect(origin: CGPoint(x: 0, y: subjectNameLabel.frame.height-10), size: CGSize(width: subjectNameLabel.frame.width, height: 0.5))
        bottomLine1.backgroundColor = UIColor.white.cgColor
        subjectNameLabel.borderStyle = UITextField.BorderStyle.none
        subjectNameLabel.layer.addSublayer(bottomLine1)
        
    }
    
    @objc func viewTapped(gestureRecognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        UIView.animate(withDuration: 0.1) { () -> Void in
            self.bottomConstraint.constant = keyboardFrame.size.height
        }
    }
    
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
    
    
    @IBAction func clearAll(_ sender: Any) {
        subjectCodeLabel.text = ""
        subjectNameLabel.text = ""
    }
    
    @IBAction func saveSubjectButton(_ sender: Any) {
        
        success = false
        
        if subjectCodeLabel.text == "" {
            displayMessage(title: "Error", message: "Please enter a subject Code.")
            return
        }
        
        if subjectNameLabel.text == "" {
            displayMessage(title: "Error", message: "Please enter a subject Name.")
            return
        }
        
        let newSubjectCode = subjectCodeLabel.text!
        let newSubjectName = subjectNameLabel.text!
        
        let updatedSubject = Subject(id: passedSubject.id, subjectCode: newSubjectCode, subjectName: newSubjectName)
        
        success = true
        
        //UPDATE SUBJECT
        databaseController!.updateSubject(subject: updatedSubject)
        displayMessage(title: "Success!", message: "Subject has been successfully Updated.")
    }
    
    
    @IBAction func deleteSubjectButton(_ sender: Any) {
        
        // create a alert action to let user confirm deletion
    
        let deleteAlert = UIAlertController(title: "Confirm Deletion", message: "This action will not only delete your subject, but also delete all tasks associated with your subject.", preferredStyle: .alert)
        
        deleteAlert.addAction(UIAlertAction(title: "Yes", style: .default) { (action) -> Void in
            
            self.databaseController!.deleteSubject(subject: self.passedSubject)
            self.success = true
            self.displayMessage(title: "Success!", message: "Subject has been successfully Deleted.")
            })

        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(deleteAlert, animated: true, completion: nil)

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
    
}
