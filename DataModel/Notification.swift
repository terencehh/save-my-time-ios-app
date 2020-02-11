//
//  Notification.swift
//  SaveMyTime
//
//  Notification Class for handling User Notifications in the App
//  Created by Terence Ng on 13/6/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

class Notification: NSObject, UNUserNotificationCenterDelegate {
    
    var notificationCenter: UNUserNotificationCenter
    
    override init() {
        
        // get the notification Center from AppDelegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.notificationCenter = appDelegate.notificationCenter
        
        super.init()
        
        notificationRequest()
    }
    
    
    func notificationRequest() {
        
        UNUserNotificationCenter.current().delegate = self
        
        // request notifications from users
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if !granted {
                print("Permission was not granted!")
                return
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler([.alert, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        completionHandler()
    }
    
    // schedules notifications
    func scheduleNotification(message: String, type: String, timeOccurence: Int) {
        
        let content = UNMutableNotificationContent()
        
        content.title = type
        content.body = message
        content.sound = UNNotificationSound.default
        content.badge = 1
        content.categoryIdentifier = type
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(timeOccurence), repeats: true)
        let request = UNNotificationRequest(identifier: type, content: content, trigger: trigger)
        
        notificationCenter.add(request) { (error) in
            if let error = error {
                print("Error \(error.localizedDescription)")
            }
        }
    }
}



