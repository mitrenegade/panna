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
import Batch
import Parse
import Fabric
import Crashlytics

var firRef = FIRDatabase.database().reference() // Firebase(url: "https://lotsportz.firebaseio.com");
let firAuth = FIRAuth.auth()

let PARSE_APP_ID: String = "Y1kUP1Nwz77UlFW5wIGvK4ptgvCwKQjDejrXbMi7"
let PARSE_CLIENT_KEY: String = "NOTUSED-O7G1syjw0PXZTOmV0FTvsH9TSTvk7e7Ll6qpDWfW"

// Selector Syntatic sugar: https://medium.com/swift-programming/swift-selector-syntax-sugar-81c8a8b10df3#.a6ml91o38
private extension Selector {
    // private to only this swift file
    static let didLogin =
        #selector(AppDelegate.didLogin)
    static let didLogout =
        #selector(AppDelegate.didLogout)
}

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
        
        // Parse
        let configuration = ParseClientConfiguration {
            $0.applicationId = PARSE_APP_ID
            $0.clientKey = PARSE_CLIENT_KEY
            $0.server = "https://lotsportz.herokuapp.com/parse"
        }
        Parse.initializeWithConfiguration(configuration)
        
        // Crashlytics
        Fabric.with([Crashlytics.self])

        return true
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        print("local notification received: \(notification)")
        let alert = UIAlertController(title: "Alert", message: "You have an event in one hour!", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        
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
        NotificationService.clearAllNotifications()
        
        // first dismiss main app
        self.window?.rootViewController?.dismissViewControllerAnimated(true, completion: {
            // load main flow
            self.revealController = nil
            self.goToSignupLogin()
        })
    }
    
    // Push
    // MARK: - Push
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        // Store the deviceToken in the current Installation and save it to Parse
        
        NotificationService.registerForPushNotifications(deviceToken, enabled:true)
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("failed: error \(error)")
        NSNotificationCenter.defaultCenter().postNotificationName("push:enable:failed", object: nil)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        print("notification received: \(userInfo)")
        /* format:
         [aps: {
         alert = "test push 2";
         sound = default;
         }]
         
         ]
         */
        guard let title = userInfo["title"] as? String else { return }
        guard let message = userInfo["message"] as? String else { return }
        guard let sender = userInfo["sender"] as? String where sender != firAuth?.currentUser!.uid else {
            print("Own message, ignoring")
            return
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        
        self.revealController?.presentViewController(alert, animated: true, completion: nil)
    }

}

