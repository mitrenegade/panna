//
//  AppDelegate.swift
// Balizinha
//
//  Created by Bobby Ren on 5/8/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import Batch
import Fabric
import Crashlytics
import RxSwift
import Stripe

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let disposeBag = DisposeBag()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Firebase
        // Do not include infolist in project: https://firebase.google.com/docs/configure/#reliable-analytics
        let plistFilename = "GoogleService-Info\(TESTING ? "-dev" : "")"
        let filePath = Bundle.main.path(forResource: plistFilename, ofType: "plist")
        assert(filePath != nil, "File doesn't exist")
        if let path = filePath, let fileopts = FirebaseOptions.init(contentsOfFile: path) {
            FirebaseApp.configure(options: fileopts)
        }
        Database.database().isPersistenceEnabled = true
        
        // Facebook
        FBSDKAppEvents.activateApp()
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Crashlytics
        Fabric.sharedSDK().debug = true
        Fabric.with([Crashlytics.self])

        // notifications
        if #available(iOS 10.0, *) {
            NotificationService.shared.registerForRemoteNotifications()
        } else {
            // Fallback on earlier versions
        }
        
        // Background fetch
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        logPlayerLogin()
        
        let STRIPE_KEY = TESTING ? STRIPE_KEY_DEV : STRIPE_KEY_PROD
        STPPaymentConfiguration.shared().publishableKey = STRIPE_KEY
        
        self.listenFor(NotificationType.LoginSuccess, action: #selector(logPlayerLogin), object: nil)

        let _ = SettingsService.shared

        return true
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        print("local notification received: \(notification)")
        if let info = notification.userInfo {
            if let type = info["type"] as? String, type == "donationReminder", let eventId = info["eventId"] as? String {
                print("Go to donation for event \(eventId)")
                guard SettingsService.donation() else { return }
                self.notify(NotificationType.GoToDonationForEvent, object: nil, userInfo: ["eventId": eventId])
            }
        }
        else {
            let alert = UIAlertController(title: "Alert", message: "You have an event in one hour!", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            self.window?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    // MARK: - Push
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Store the deviceToken
        if #available(iOS 10.0, *) {
            NotificationService.shared.didRegisterForRemoteNotifications(deviceToken: deviceToken)
        } else {
            // Fallback on earlier versions
            print("PUSH: TODO handle for ios9")
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("PUSH: registration failed: error \(error)")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "push:enable:failed"), object: nil)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // iOS 9
        
        print("PUSH: notification received: \(userInfo)")
        /* format:
         [aps: {
         alert = "test push 2";
         sound = default;
         }]
         
         ]
         */
        guard let title = userInfo["title"] as? String else { return }
        guard let message = userInfo["message"] as? String else { return }
        guard let sender = userInfo["sender"] as? String, sender != firAuth.currentUser!.uid else {
            print("Own message, ignoring")
            return
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
        
        let gcmMessageIDKey = "gcm.message_id"

        // FCM
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // iOS 9
        
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        print("PUSH: didReceiveRemoteNotification from background")
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }

}

// MARK: - Background fetch
extension AppDelegate {
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("PUSH: background fetch")
        LoggingService.shared.log(event: "BackgroundFetch", info: nil)
        completionHandler(UIBackgroundFetchResult.newData)
    }
}

extension AppDelegate {
    func logPlayerLogin() {
        // TODO: FIX THIS BEFORE RELEASE - try new devices
        // TODO: on logout/login, this doesn't get triggered again
        guard let observable = PlayerService.shared.observedPlayer else {
            print("doh")
            return
        }
        observable.take(1).subscribe(onNext: { (player) in
//            LoggingService.shared.log(event: "testWriteRemoteData", info: nil)
//            RemoteDataService.shared.post(userId: player.id, message: "testing")
            
            // checks for stripe customer
            StripeService().checkForStripeCustomer(player)
        }, onError: { (error) in
            print("error \(error)")
        }, onCompleted: { 
            print("completed")
        }, onDisposed: {
            print("disposed")
        }).addDisposableTo(disposeBag)
    }
}
