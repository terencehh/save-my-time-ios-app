//
//  UserProfileViewController.swift
//  SaveMyTime
//  This class displays the user's account information
//  User information is stored in Firebase, hence database Controller is used to retrieve the information
//
//  Created by Terence Ng on 6/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit
import FirebaseAuth

// Class View displaying user's profile information
// this class will need to download data from firestore to present user profile data - user data + user profile data
class UserProfileViewController: UIViewController, UITextFieldDelegate{
    
    weak var databaseController: DatabaseProtocol?
    
    // Retrieve important references
    @IBOutlet weak var fnameLabel: UILabel!
    @IBOutlet weak var lnameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    
    var passwordLabel: String!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Get the database controller once from the App Delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController
    
    }
    
    override func viewDidAppear(_ animated: Bool) {

        super.viewDidAppear(true)
        
        // Retrieve the user's profile image for display
        // for simplicity, we always download the user profile
        databaseController?.downloadProfilePicture() { (image) -> Void in
            if let image = image {
                DispatchQueue.main.async {
                    self.profileImage.image = image
                }
            }
        }

        // Retrieve the user's profile data for display
        databaseController?.downloadProfile() { (Profile) -> Void in
            if let Profile = Profile {
                DispatchQueue.main.async {
                    self.fnameLabel.text = (Profile["firstName"]! as! String)
                    self.lnameLabel.text = (Profile["lastName"]! as! String)
                    self.usernameLabel.text = (Profile["username"]! as! String)
                    self.passwordLabel = (Profile["password"]! as! String)
                    self.emailLabel.text = (Profile["email"]! as! String)
                }
            }
        }
    }
    
    // Dismiss the keyboard when the return key is tapped
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    // Deletes user profile
    // On deletion, user authentication is removed from firebase firestore
    // App is returned to initial screen afterwards
    @IBAction func deleteProfileButton(_ sender: Any) {
        
        // create a alert action to let user confirm deletion
        
        let deleteAlert = UIAlertController(title: "Confirm Deletion", message: "The Following action will delete all your data permanently. Are you Sure?", preferredStyle: .alert)
        
        deleteAlert.addAction(UIAlertAction(title: "Yes", style: .default) { (action) -> Void in
            
            let email = self.emailLabel.text!
            let password = self.passwordLabel
            let user = Auth.auth().currentUser
            
            let credential: AuthCredential = EmailAuthProvider.credential(withEmail: email, password: password!)
            
            // first reauthenticate user - for simplicity - we will reauthenticate it ourse
            user?.reauthenticateAndRetrieveData(with: credential) { (result, error) in
                if let error = error {
                    print(error)
                }
                else {
                    print("User re-authenticated")
                    self.databaseController?.deleteUserProfile() { (bool) -> Void in
                        
                        if let bool = bool {
                            // IF SUCCESSFULLY DELETED USER
                            if bool == true {
                                
                                DispatchQueue.main.async {
                                    // return to home screen after deleting user and their data
                                    self.navigationController?.popToRootViewController(animated: true)
                                }
                            }
                        }
                    }
                }
            }
        })
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(deleteAlert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "updateProfileSegue" {
            let destination = segue.destination as! UpdateUserViewController
            
            destination.fname = fnameLabel.text!
            destination.lname = lnameLabel.text!
            destination.username = usernameLabel.text!
            destination.password = passwordLabel
            destination.email = emailLabel.text!
            destination.profileImage = profileImage.image
        }
    }
}
