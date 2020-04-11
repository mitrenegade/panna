//
//  AppDelegate.swift
// Balizinha
//
//  Created by Bobby Ren on 5/8/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Firebase
import FirebaseMessaging
import Batch
import Fabric
import Crashlytics
import RxSwift
import Stripe
import RxOptional
import Balizinha
import RenderCloud
import FBSDKCoreKit
import RenderPay

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let disposeBag = DisposeBag()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Firebase
        // Do not include infolist in project: https://firebase.google.com/docs/configure/#reliable-analytics
        let plistFilename = "GoogleService-Info\(TESTING ? "-dev" : "")"
        let filePath = Bundle.main.path(forResource: plistFilename, ofType: "plist")
        assert(filePath != nil, "File doesn't exist")
        if let path = filePath, let fileopts = FirebaseOptions.init(contentsOfFile: path) {
            FirebaseApp.configure(options: fileopts)
        }
        let urlSuffix = TESTING ? "-dev" : "-c9cd7"
        RenderAPIService.baseURL = URL(string: "https://us-central1-balizinha\(urlSuffix).cloudfunctions.net/")

        // Facebook
        AppEvents.activateApp()
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)

        // Background fetch
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        let STRIPE_KEY = TESTING ? STRIPE_KEY_DEV : STRIPE_KEY_PROD
        STPPaymentConfiguration.shared().publishableKey = STRIPE_KEY

        let _ = SettingsService.shared

        // handle any deeplink
        DeepLinkService.shared.checkDeepLink()

        if TESTING {
            UIFont.printAvailableFonts()
        }
        
        // push delegates - must be done before app finishes launching
        // For iOS 10 display notification (sent via APNS)
        UNUserNotificationCenter.current().delegate = NotificationService.shared
        
        // Messaging service delegate - for data messages
        Messaging.messaging().delegate = NotificationService.shared

        let _ = LeagueService.shared
        
        // GMSServices.provideAPIKey(TESTING ? GOOGLE_API_KEY_DEV : GOOGLE_API_KEY_PROD)

        UINavigationBar.appearance().backgroundColor = PannaUI.navBarTint
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.montserratSemiBold(size: 20)]
        UIApplication.shared.statusBarStyle = .lightContent
        return true
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        print("local notification received: \(notification)")
        if let info = notification.userInfo {
            print("local notification has info \(info)")
        }
        else {
            let alert = UIAlertController(title: "Alert", message: "You have an event in one hour!", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            self.window?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }

    // MARK: - Push
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // let Messaging delegate handle token storage
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
        guard let sender = userInfo["sender"] as? String, sender != AuthService.currentUser?.uid else {
            print("Own message, ignoring")
            return
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
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
        LoggingService.shared.log(event: LoggingEvent.BackgroundFetch, info: nil)
        completionHandler(UIBackgroundFetchResult.newData)
    }
}

// MARK: - Deeplinking
extension AppDelegate {
    // deeplinking from a scheme like panna://events/eventId
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        // returns facebook, custom scheme deep links
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true), (components.scheme == "balizinha" || components.scheme == "panna") {
            return DeepLinkService.shared.handle(url: url)
        }
        return ApplicationDelegate.shared.application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // for handling dynamic links passed as custom scheme urls - not used (??)
        if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url), let url = dynamicLink.url {
            return DeepLinkService.shared.handle(url: url)
        }
        return ApplicationDelegate.shared.application(app, open: url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, annotation: options[.annotation])
    }
    
    // universal links
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        print("User activity type \(userActivity.activityType) url \(String(describing: userActivity.webpageURL?.absoluteString))")
        let handled = DynamicLinks.dynamicLinks().handleUniversalLink(userActivity.webpageURL!) { (link, error) in
            if let error = error {
                print("Deeplink error \(error)")
            } else if let url = link?.url {
                let _ = DeepLinkService.shared.handle(url: url)
            }
        }
        return handled
    }
}
