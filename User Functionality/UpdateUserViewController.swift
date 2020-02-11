//
//  UpdateUserViewController.swift
//  SaveMyTime

//  This Class allows the user to update their profile information
//  Created by Terence Ng on 24/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications


class UpdateUserViewController: UIViewController, UITextFieldDelegate {
    
    weak var databaseController: DatabaseProtocol?

    var user: User?
    
    // data passed from segue
    // if have time can refactor to send a Profile class instead - less code, more readable
    var fname: String!
    var lname: String!
    var username: String!
    var password: String!
    var email: String!
    var profileImage: UIImage!

    // This constraint gets pushed up if the keyboard shows
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var fnameTextField: UITextField!
    @IBOutlet weak var lnameTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var tapToChangeProfileButton: UIButton!
    
    @IBOutlet weak var profileImagePlaceholder: UIImageView!
    
    var imagePicker: UIImagePickerController!
    
    // represents whether profile has been updated successfully
    var success: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(gestureRecognizer:)))
        view.addGestureRecognizer(tapGesture)
        
        // Get the database controller once from the App Delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController
        
        
        // Implement observers which push the view up on keyboard pop-up
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        

        // Assign initial values from the user details passed from the segue before
        fnameTextField.text = fname
        lnameTextField.text = lname
        usernameTextField.text = username
        emailTextField.text = email
        passwordTextField.text = password
        
        profileImagePlaceholder.image = profileImage
        
        // make sure the text field implements the delegate to 'return' after keyboard return press
        fnameTextField.delegate = self
        lnameTextField.delegate = self
        usernameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        // this ensures the view dismisses when user touches anywhere on the view controller
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        // this is for allow the image to be tappable by the user
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(openImagePicker))
        profileImagePlaceholder.isUserInteractionEnabled = true
        profileImagePlaceholder.addGestureRecognizer(imageTap)
        
        tapToChangeProfileButton.addTarget(self, action: #selector(openImagePicker), for: .touchUpInside)
        
        // Do any additional setup after loading the view.
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        // perform reauthentication - for simplicity - we do it automatically for user
        user = Auth.auth().currentUser
        let credential: AuthCredential = EmailAuthProvider.credential(withEmail: email!, password: password!)
        
        user?.reauthenticateAndRetrieveData(with: credential) { (result, error) in
            if let error = error {
                print(error)
            }
            else {
                print("User re-authenticated")
            }
        }
        
        // create underlined line for input textfield
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(origin: CGPoint(x: 0, y: fnameTextField.frame.height-10), size: CGSize(width: fnameTextField.frame.width, height: 0.5))
        bottomLine.backgroundColor = UIColor.white.cgColor
        fnameTextField.borderStyle = UITextField.BorderStyle.none
        fnameTextField.layer.addSublayer(bottomLine)
        
        // create underlined line for input textfield
        let bottomLine1 = CALayer()
        bottomLine1.frame = CGRect(origin: CGPoint(x: 0, y: lnameTextField.frame.height-10), size: CGSize(width: lnameTextField.frame.width, height: 0.5))
        bottomLine1.backgroundColor = UIColor.white.cgColor
        lnameTextField.borderStyle = UITextField.BorderStyle.none
        lnameTextField.layer.addSublayer(bottomLine1)
        
        // create underlined line for input textfield
        let bottomLine2 = CALayer()
        bottomLine2.frame = CGRect(origin: CGPoint(x: 0, y: usernameTextField.frame.height-10), size: CGSize(width: usernameTextField.frame.width, height: 0.5))
        bottomLine2.backgroundColor = UIColor.white.cgColor
        usernameTextField.borderStyle = UITextField.BorderStyle.none
        usernameTextField.layer.addSublayer(bottomLine2)
        
        // create underlined line for input textfield
        let bottomLine3 = CALayer()
        bottomLine3.frame = CGRect(origin: CGPoint(x: 0, y: emailTextField.frame.height-10), size: CGSize(width: emailTextField.frame.width, height: 0.5))
        bottomLine3.backgroundColor = UIColor.white.cgColor
        emailTextField.borderStyle = UITextField.BorderStyle.none
        emailTextField.layer.addSublayer(bottomLine3)
        
        // create underlined line for input textfield
        let bottomLine4 = CALayer()
        bottomLine4.frame = CGRect(origin: CGPoint(x: 0, y: passwordTextField.frame.height-10), size: CGSize(width: passwordTextField.frame.width, height: 0.5))
        bottomLine4.backgroundColor = UIColor.white.cgColor
        passwordTextField.borderStyle = UITextField.BorderStyle.none
        passwordTextField.layer.addSublayer(bottomLine4)
        
    }
    
    // ends editing in the view
    @objc func viewTapped(gestureRecognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    // function which pushes view up on keyboard show
    @objc func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        UIView.animate(withDuration: 0.1) { () -> Void in
            self.bottomConstraint.constant = keyboardFrame.size.height - 40
        }
    }
    // restore view on keyboard dismissal
    @objc func keyboardWillHide(notification: NSNotification) {
        
        UIView.animate(withDuration: 0.1) { () -> Void in
            self.bottomConstraint.constant = 32.5
        }
    }
    
    // image picker for changing profile picture
    @objc func openImagePicker(_ sender:Any) {
        
        // check if device has a camera
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .camera
        }
        else {
            imagePicker.allowsEditing = true
            imagePicker.sourceType = .photoLibrary
        }
        // Opens the image Picker
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    // Dismiss the keyboard when the return key is tapped
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    @IBAction func clearAll(_ sender: Any) {
        fnameTextField.text = ""
        lnameTextField.text = ""
        passwordTextField.text = ""
        usernameTextField.text = ""
        emailTextField.text = ""
        passwordTextField.text = ""
    }
    
    // saves changes to the profile
    // Performs user validation first
    // If successful, pop the view controller back from segue
    @IBAction func saveProfileButton(_ sender: Any) {
        
        // perform validation of input fields before saving data
        
        if fnameTextField.text == "" {
            displayMessage(title: "Error", message: "Please enter a first name.")
            return
        }
        
        if lnameTextField.text == "" {
            displayMessage(title: "Error", message: "Please enter a last name.")
            return
        }
        
        if passwordTextField.text == "" {
            displayMessage(title: "Error", message: "Please enter a password.")
            return
        }
        
        if usernameTextField.text == "" {
            displayMessage(title: "Error", message: "Please enter a username.")
            return
        }
        
        if emailTextField.text == "" {
            displayMessage(title: "Error", message: "Please enter an email address.")
            return
        }
        
        // check if valid email
        if  validateEmail(candidate: emailTextField.text!) != true {
            displayMessage(title: "Error", message: "Please enter a valid email address format.")
            return
        }
        
        let username = usernameTextField.text!
        let fname = fnameTextField.text!
        let lname = lnameTextField.text!
        let password = passwordTextField.text!
        let email = emailTextField.text!
        let image = self.profileImagePlaceholder.image!
        
        var outputMessage = "The Following changes have been made.\n"
        var changeCount = 0
        
        // if image changed
        if profileImage != image {
            outputMessage += "-Profile Picture Updated.\n"
            changeCount += 1
        }
        
        // if email changed
        if email != self.email {
            
            outputMessage += "-Email Address Updated.\n"
            changeCount += 1
            
            user?.updateEmail(to: email) { error in
                if let error = error {
                    print(error)
                } else {
                    print("Email Updated")

                }
            }
        }
        
        // if password changed
        if password != self.password {
            
            outputMessage += "Password Updated.\n"
            changeCount += 1

            user?.updatePassword(to: password) { error in
                if let error = error {
                    print(error)
                } else {
                    print("-Password Updated")
                }
            }
        }
        
        // if anything else from profile changed - update profile
        if username != self.username || fname != self.fname || lname != self.lname {
            
            // save the user profile data
            outputMessage += "-Profile Data Updated.\n"
            changeCount += 1
            print("Updated Profile Data")

        }
        
        if changeCount > 0 {
            self.success = true
            self.databaseController?.saveProfile(username: username, firstName: fname, lastName: lname, password: password, email: email)
            
            self.displayMessage(title: "Successful!", message: outputMessage + "\nPlease give some time in order to see the changes." )
            
        } else {
            self.displayMessage(title: "Error", message: "Please make at least one change to update your profile.")
        }
    }
    
    // Function which displays alerts
    func displayMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default) { (UIAlertAction) -> Void in
            
            // if successfully updated profile, then pop view controller to root
            if self.success {
                
                self.success = false
                
                CATransaction.begin()
                self.navigationController?.popViewController(animated: true)
                CATransaction.commit()
            }
        })
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    // function to determine if string is an email
    // Taken from http://emailregex.com
    // Date: 24 May 2019
    func validateEmail(candidate: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: candidate)
    }
}

// Extension for Image Picker
extension UpdateUserViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            profileImagePlaceholder.image = pickedImage
        }
        
        // save the user profile picture by overriding the user's current picture's directory
        // immediately download image into firebase to ensure faster completion
        let image = self.profileImagePlaceholder.image!
        self.databaseController?.uploadProfilePicture(image: image)
        
        picker.dismiss(animated: true, completion: nil)
    }
    
}
