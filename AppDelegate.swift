//
//  AppDelegate.swift
//  SaveMyTime
//
//  Created by Terence Ng on 5/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import UserNotifications


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    
    var notificationCenter = UNUserNotificationCenter.current()
    // custom class created to handle all notification logic
    var notification:Notification?
    
    // database for online firebase functionality
    var databaseController: DatabaseProtocol?
    
    // container for offline functionality

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        notification = Notification()
        notificationCenter.delegate = self
        
        // Configuring online functionality via Firebase
        FirebaseApp.configure()
        databaseController = FirebaseController()
        
        // Google Sign in
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self
        
        // Determine the initial root view controller by checking if user already authenticated

        self.window = UIWindow(frame:UIScreen.main.bounds)
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        if Auth.auth().currentUser != nil {
            databaseController?.setUserSession(sessionID: Auth.auth().currentUser!.uid)
            let initialViewController: UITabBarController = mainStoryboard.instantiateViewController(withIdentifier: "alreadyLoggedIn") as! UITabBarController
            self.window?.rootViewController = initialViewController
        } else {
            let initialViewController: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "notLoggedIn") as UIViewController
            self.window?.rootViewController = initialViewController
        }
        
        self.window?.makeKeyAndVisible()

        return true
    }
    
    
    // Handles sign-in if user chooses google sign in
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!){
        
        if error != nil {
            return
        }
        
        guard let authentication = user.authentication else { return }
        
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)

        Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
                return
            }
            
            // user is signed in, set session ID and go to home page
            print("Signed in Successfully")
            self.databaseController?.setUserSession(sessionID: (Auth.auth().currentUser?.uid)!)
            
            if let rootVC = self.window?.rootViewController {
                rootVC.performSegue(withIdentifier: "toMainPage", sender: self)
            }
            
            
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from here.
    }
    

    // handles authentication from external social sources
    // returns true if allows
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance().handle(url,
                                                 sourceApplication:options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                                                 annotation: [:])
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        
        

    }

    // Function invoked whenever app enters background
    // it determines which notifications to schedule
    // and if the user is in an active focus session
    // schedules procrastination alarms
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        if Auth.auth().currentUser != nil {
            
            print("App Entering the background, Scheduling Future Notifications")
            // schedule notifications when app enter's the background
            databaseController!.determineTaskNotifications()
            
            if databaseController!.getTimerRunning() == true {
                
                databaseController!.determineProcrastinationNotifications()
                databaseController!.setFocusSession(active: false)
            }
        }
        

    }

    // Function invoked whenever app is back in foreground
    // It removes current notifications and alarms that have been occuring in the background
    func applicationWillEnterForeground(_ application: UIApplication) {
        
        if Auth.auth().currentUser != nil {
            
            if databaseController!.getTimerRunning() == true {
                databaseController!.setFocusSession(active: true)
            }
        
            print("App back in Foreground, Removing current Notifications")
            // Remove all past notification configurations when app is launched/restored in foreground
            notificationCenter.removeAllPendingNotificationRequests()
            databaseController!.removeAlarm()
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

