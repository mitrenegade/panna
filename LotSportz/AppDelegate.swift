//
//  AppDelegate.swift
//  LotSportz
//
//  Created by Bobby Ren on 5/8/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import SWRevealViewController

var firRef = FIRDatabase.database().reference() // Firebase(url: "https://lotsportz.firebaseio.com");
let firAuth = FIRAuth.auth()

// Selector Syntatic sugar: https://medium.com/swift-programming/swift-selector-syntax-sugar-81c8a8b10df3#.a6ml91o38
private extension Selector {
    // private to only this swift file
    static let didLogin =
        #selector(AppDelegate.didLogin)
    static let didLogout =
        #selector(AppDelegate.didLogout)
}

let kEventNotificationIntervalSeconds: NSTimeInterval = -3600
let kEventNotificationMessage: String = "You have an event in 1 hour!"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var handle: FIRAuthStateDidChangeListenerHandle?
    var revealController: SWRevealViewController?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        //enable local notifications
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Sound, .Alert, .Badge], categories: nil))

        // Firebase
        FIRApp.configure()
        
        self.handle = firAuth?.addAuthStateDidChangeListener({ (auth, user) in
            if let user = user {
                // user is logged in
                print("auth: \(auth) user: \(user)")
                self.goToMenu()

            }
            else {
                self.goToSignupLogin()
            }
        })
        
        // Facebook
        FBSDKAppEvents.activateApp()
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        return true
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        print("local notification received: \(notification)")
        let alert = UIAlertController(title: "Alert", message: "You have an event in one hour!", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        
 //       self.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
        self.revealController?.presentViewController(alert, animated: true, completion: nil)
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    // MARK: - Navigation
    func goToSignupLogin() {
        let nav = UIStoryboard(name: "LoginSignup", bundle: nil).instantiateViewControllerWithIdentifier("LoginSignupNavigationController") as! UINavigationController
        self.window?.rootViewController?.presentViewController(nav, animated: true, completion: nil)
        if self.handle != nil {
            firAuth?.removeAuthStateDidChangeListener(self.handle!)
            self.handle = nil
        }
        
        self.listenFor("login:success", action: .didLogin, object: nil)
    }
    
    func didLogin() {
        print("logged in")
        self.stopListeningFor("login:success")

        // first dismiss login/signup flow
        self.window?.rootViewController?.dismissViewControllerAnimated(true, completion: {
            // load main flow
            self.goToMenu()
        })
    }
    
    func goToMenu() {
        if self.revealController != nil {
            return
        }
        
        let controller = UIStoryboard(name: "Menu", bundle: nil).instantiateViewControllerWithIdentifier("RevealViewController") as! SWRevealViewController
        self.window?.rootViewController?.presentViewController(controller, animated: true, completion: nil)
        self.revealController = controller
        self.listenFor("logout:success", action: .didLogout, object: nil)
    }
    
    func didLogout() {
        print("logged out")
        self.stopListeningFor("logout:Success")
        
        // first dismiss main app
        self.window?.rootViewController?.dismissViewControllerAnimated(true, completion: {
            // load main flow
            self.revealController = nil
            self.goToSignupLogin()
        })
    }
}

