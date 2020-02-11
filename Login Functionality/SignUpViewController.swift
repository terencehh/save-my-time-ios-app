//
//  CreateAccountViewController.swift
//  SaveMyTime
//  This class handles initial User Sign-up
//
//  Created by Terence Ng on 5/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore


class SignUpViewController: UIViewController, UITextFieldDelegate {

    // Get a reference to the database controller in App Delegate
    weak var databaseController: DatabaseProtocol?
    
    // Get a reference to all the input fields in this view
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!
    
    // This button interacts with the image picker to change profile picture
    @IBOutlet weak var tapToChangeButton: UIButton!
    
    // get a reference to bottom constraint in order to push view up when keyboard is blocking fields
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    // Image picker for profile picture
    var imagePicker: UIImagePickerController!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add a tap gesture which dismisses the keyboard on view tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(gestureRecognizer:)))
        view.addGestureRecognizer(tapGesture)
        
        // set profile picture
        profileImageView.image = UIImage(named: "GOOD")
        
        // make sure textfields implement their delegate for custom behaviours
        usernameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        // Get the database controller once from the App Delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController
        
        // Add observers which alter the bottom constraint on keyboard pop-up
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        // this ensures the view dismisses when user touches anywhere on the view controller
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        // configure the profile image functionality
        // this allows the image to be tappable by the user, invoking a function which brings up the image picker
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(openImagePicker))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(imageTap)
        profileImageView.layer.cornerRadius = profileImageView.bounds.height / 2
        profileImageView.clipsToBounds = true
        tapToChangeButton.addTarget(self, action: #selector(openImagePicker), for: .touchUpInside)
        
        // configure the image picker
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        // create underlined line for input textfield
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(origin: CGPoint(x: 0, y: usernameTextField.frame.height-10), size: CGSize(width: usernameTextField.frame.width, height: 0.5))
        bottomLine.backgroundColor = UIColor.white.cgColor
        usernameTextField.borderStyle = UITextField.BorderStyle.none
        usernameTextField.layer.addSublayer(bottomLine)
        
        // create underlined line for input textfield
        let bottomLine1 = CALayer()
        bottomLine1.frame = CGRect(origin: CGPoint(x: 0, y: emailTextField.frame.height-10), size: CGSize(width: emailTextField.frame.width, height: 0.5))
        bottomLine1.backgroundColor = UIColor.white.cgColor
        emailTextField.borderStyle = UITextField.BorderStyle.none
        emailTextField.layer.addSublayer(bottomLine1)
        
        // create underlined line for input textfield
        let bottomLine2 = CALayer()
        bottomLine2.frame = CGRect(origin: CGPoint(x: 0, y: passwordTextField.frame.height-10), size: CGSize(width: passwordTextField.frame.width, height: 0.5))
        bottomLine2.backgroundColor = UIColor.white.cgColor
        passwordTextField.borderStyle = UITextField.BorderStyle.none
        passwordTextField.layer.addSublayer(bottomLine2)
        
    }
    
    // ends any keyboard editing on the view
    @objc func viewTapped(gestureRecognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    // function for altering bottom constraint
    @objc func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        UIView.animate(withDuration: 0.1) { () -> Void in
            self.bottomConstraint.constant = keyboardFrame.size.height + 20
        }
    }
    
    // function to resture bottom constraint
    @objc func keyboardWillHide(notification: NSNotification) {
        
        UIView.animate(withDuration: 0.1) { () -> Void in
            self.bottomConstraint.constant = 50
        }
    }
    
    // function which invokes the image picker
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

    // go back to root page
    @IBAction func backButton(_ sender: Any) {
        // Replace the storyboard and reset it to initial login page
        // Solution was taken at StackOverflow and altered by Terence Ng
        // https://stackoverflow.com/questions/37051676/change-mainviewcontroller-in-ios-with-swift-after-login
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "notLoggedIn")
    }
    
    // Performs initial user sign-up
    // Contains user validation
    // If successful, create a user in Firebase and send user to Main Page
    @IBAction func signUpButton(_ sender: Any) {
        
        if passwordTextField.text!.count == 0 {
            displayMessage(title: "Error", message: "Please enter a password.")
            return
        }
        
        if emailTextField.text!.count == 0 {
            displayMessage(title: "Error", message: "Please enter an email address.")
            return
        }
        
        if usernameTextField.text!.count == 0 {
            displayMessage(title: "Error", message: "Please enter a username")
            return
        }
        
        let image = profileImageView.image!
        let email = emailTextField.text!
        let username = usernameTextField.text!
        let password = passwordTextField.text!
        

        // Register user with Firebase
        Auth.auth().createUser(withEmail: email, password: password) { user, error in
            
            if error == nil {
                
                print("User Created!")
                // save the user ID session
                self.databaseController?.setUserSession(sessionID: (Auth.auth().currentUser?.uid)!)
                
                
                // Upload profile image to firebase storage
                self.databaseController?.uploadProfilePicture(image: image)
                
                // Save the profile data to firestore database
                let _ = self.databaseController?.saveProfile(username: username, firstName: "Not Specified", lastName: "Not Specified", password: password, email: email)
                print("User Profile Data Stored!")
                
                self.performSegue(withIdentifier: "toMainPage", sender: self)
                
            }
                
            else {
                // Error for uploading profile image
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
}

// extension for image picker properties
extension SignUpViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            profileImageView.image = pickedImage
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
}



