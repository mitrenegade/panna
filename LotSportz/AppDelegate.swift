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

var firebaseRef = Firebase(url: "https://lotsportz.firebaseio.com");

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
    var handle: UInt?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // Firebase
        self.handle = firebaseRef.observeAuthEventWithBlock { (authData) -> Void in
            if authData != nil {
                // user is logged in
                print("authdata: \(authData)")
                self.goToMain()
            }
            else {
                self.goToSignupLogin()
            }
            
        }
        
        // Facebook
        FBSDKAppEvents.activateApp()
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    // MARK: - Navigation
    func goToSignupLogin() {
        let nav = UIStoryboard(name: "LoginSignup", bundle: nil).instantiateViewControllerWithIdentifier("LoginSignupNavigationController") as! UINavigationController
        self.window?.rootViewController?.presentViewController(nav, animated: true, completion: nil)
        firebaseRef.removeObserverWithHandle(self.handle!)
        
        self.listenFor("login:success", action: .didLogin, object: nil)
    }
    
    func didLogin() {
        print("logged in")
        self.stopListeningFor("login:success")

        // first dismiss login/signup flow
        self.window?.rootViewController?.dismissViewControllerAnimated(true, completion: {
            // load main flow
            self.goToMain()
        })
    }
    
    func goToMain() {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("MainViewController") 
        self.window?.rootViewController?.presentViewController(controller, animated: true, completion: nil)
        firebaseRef.removeObserverWithHandle(self.handle!)
        
        self.listenFor("logout:success", action: .didLogout, object: nil)
    }
    
    func didLogout() {
        print("logged out")
        self.stopListeningFor("logout:Success")
        
        // first dismiss main app
        self.window?.rootViewController?.dismissViewControllerAnimated(true, completion: {
            // load main flow
            self.goToSignupLogin()
        })
    }
}

