//
//  UserStatisticsViewController.swift
//  SaveMyTime
//  This class displays statistics regarding the user's procrastination and focus habits
//  algorithm is created via analyzing the user's firestore information

//  Created by Terence Ng on 13/6/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit

class UserStatisticsViewController: UIViewController{
    
    weak var databaseController: DatabaseProtocol?
    
    // get references to text fields
    @IBOutlet weak var longestDayLabel: UITextField!
    @IBOutlet weak var averageFocusSession: UITextField!
    @IBOutlet weak var totalSessionLabel: UITextField!
    @IBOutlet weak var sessionSuccessRateLabel: UITextField!
    @IBOutlet weak var longestDaySessionTime: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the database controller once from the App Delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController

        // Do any additional setup after loading the view.
        
        // create underlined line for input textfield
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(origin: CGPoint(x: 0, y: longestDayLabel.frame.height-10), size: CGSize(width: longestDayLabel.frame.width, height: 0.5))
        bottomLine.backgroundColor = UIColor.white.cgColor
        longestDayLabel.borderStyle = UITextField.BorderStyle.none
        longestDayLabel.layer.addSublayer(bottomLine)
        
        // create underlined line for input textfield
        let bottomLine1 = CALayer()
        bottomLine1.frame = CGRect(origin: CGPoint(x: 0, y: averageFocusSession.frame.height-10), size: CGSize(width: averageFocusSession.frame.width, height: 0.5))
        bottomLine1.backgroundColor = UIColor.white.cgColor
        averageFocusSession.borderStyle = UITextField.BorderStyle.none
        averageFocusSession.layer.addSublayer(bottomLine1)
        
        // create underlined line for input textfield
        let bottomLine2 = CALayer()
        bottomLine2.frame = CGRect(origin: CGPoint(x: 0, y: totalSessionLabel.frame.height-10), size: CGSize(width: totalSessionLabel.frame.width, height: 0.5))
        bottomLine2.backgroundColor = UIColor.white.cgColor
        totalSessionLabel.borderStyle = UITextField.BorderStyle.none
        totalSessionLabel.layer.addSublayer(bottomLine2)
        
        // create underlined line for input textfield
        let bottomLine3 = CALayer()
        bottomLine3.frame = CGRect(origin: CGPoint(x: 0, y: sessionSuccessRateLabel.frame.height-10), size: CGSize(width: sessionSuccessRateLabel.frame.width, height: 0.5))
        bottomLine3.backgroundColor = UIColor.white.cgColor
        sessionSuccessRateLabel.borderStyle = UITextField.BorderStyle.none
        sessionSuccessRateLabel.layer.addSublayer(bottomLine3)
        
        // create underlined line for input textfield
        let bottomLine4 = CALayer()
        bottomLine4.frame = CGRect(origin: CGPoint(x: 0, y: longestDaySessionTime.frame.height-10), size: CGSize(width: longestDaySessionTime.frame.width, height: 0.5))
        bottomLine4.backgroundColor = UIColor.white.cgColor
        longestDaySessionTime.borderStyle = UITextField.BorderStyle.none
        longestDaySessionTime.layer.addSublayer(bottomLine4)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated)

        // Update user statistics whenever it changes
        databaseController!.getUserStatistics() { (totalSession, sessionSuccessRate, averageFocusSession, longestFocusTimeInDay, longestDay) -> Void in
            
            if let totalSession = totalSession {
                DispatchQueue.main.async {
                    self.totalSessionLabel.text = "\(totalSession) Sessions"
                }
            }
            
            if let sessionSuccessRate = sessionSuccessRate {
                DispatchQueue.main.async {
                    self.sessionSuccessRateLabel.text = "\(sessionSuccessRate)%"
                }
            }
            
            if let averageFocusSession = averageFocusSession {
                DispatchQueue.main.async {
                    self.averageFocusSession.text = "\(self.timeString(time: TimeInterval(averageFocusSession)))"
                }
            }
            
            if let longestFocusTimeInDay = longestFocusTimeInDay {
                DispatchQueue.main.async {
                    self.longestDaySessionTime.text = "\(self.timeString(time: TimeInterval(longestFocusTimeInDay)))"
                }
            }
            
            if let longestDay = longestDay {
                DispatchQueue.main.async {
                    self.longestDayLabel.text = "\(longestDay) Days"
                }
            }
        }
    }
    
    // function for formatting a string via seconds
    // Taken and modified from https://stackoverflow.com/questions/52215882/ios-how-to-create-countdown-time-hours-minutes-seccond-swift-4
    func timeString(time: TimeInterval) -> String {
        
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if time > 3600 {
            return String(format: "%2i Hour, %2i Minute, %2i Second", hours, minutes, seconds)
        }
        
        else if time > 60 {
            return String(format: "%2i Minute, %2i Second", minutes, seconds)
        }
        
        else {
            return String(format: "%2i Second", seconds)
        }
    }
}
