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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //enable local notifications
        application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil))

        // Firebase
        FIRApp.configure()
        self.handle = firAuth?.addStateDidChangeListener({ (auth, user) in
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
        Parse.initialize(with: configuration)
        
        // Crashlytics
        Fabric.with([Crashlytics.self])

        return true
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        print("local notification received: \(notification)")
        let alert = UIAlertController(title: "Alert", message: "You have an event in one hour!", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        self.revealController?.present(alert, animated: true, completion: nil)
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    // MARK: - Navigation
    func goToSignupLogin() {
        let nav = UIStoryboard(name: "LoginSignup", bundle: nil).instantiateViewController(withIdentifier: "LoginSignupNavigationController") as! UINavigationController
        self.window?.rootViewController?.present(nav, animated: true, completion: nil)
        if self.handle != nil {
            firAuth?.removeStateDidChangeListener(self.handle!)
            self.handle = nil
        }
        
        self.listenFor("login:success", action: .didLogin, object: nil)
    }
    
    func didLogin() {
        print("logged in")
        self.stopListeningFor("login:success")

        // first dismiss login/signup flow
        self.window?.rootViewController?.dismiss(animated: true, completion: {
            // load main flow
            self.goToMenu()
        })
    }
    
    func goToMenu() {
        if self.revealController != nil {
            return
        }
        
        let controller = UIStoryboard(name: "Menu", bundle: nil).instantiateViewController(withIdentifier: "RevealViewController") as! SWRevealViewController
        self.window?.rootViewController?.present(controller, animated: true, completion: nil)
        self.revealController = controller
        self.listenFor("logout:success", action: .didLogout, object: nil)
        
        EventService.sharedInstance().listenForEventUsers()
    }
    
    func didLogout() {
        print("logged out")
        self.stopListeningFor("logout:Success")
        NotificationService.clearAllNotifications()
        
        // first dismiss main app
        self.window?.rootViewController?.dismiss(animated: true, completion: {
            // load main flow
            self.revealController = nil
            self.goToSignupLogin()
        })
    }
    
    // Push
    // MARK: - Push
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Store the deviceToken in the current Installation and save it to Parse
        
        NotificationService.registerForPushNotifications(deviceToken, enabled:true)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("failed: error \(error)")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "push:enable:failed"), object: nil)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
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
        guard let sender = userInfo["sender"] as? String, sender != firAuth?.currentUser!.uid else {
            print("Own message, ignoring")
            return
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        self.revealController?.present(alert, animated: true, completion: nil)
    }

}

