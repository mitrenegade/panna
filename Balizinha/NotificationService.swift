//
//  NotificationService.swift
// Balizinha
//
//  Created by Bobby Ren on 6/28/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import UserNotifications
import FirebaseDatabase
import FirebaseMessaging
import FirebaseInstanceID
import Firebase
import RxSwift
import RxOptional
import Balizinha

let kEventNotificationIntervalSeconds: TimeInterval = -3600
let kEventNotificationMessage: String = "You have an event in 1 hour!"

let gcmMessageIDKey = "gcm.message_id"

enum NotificationType: String {
    case EventsChanged
    case PaymentContextChanged
    case LocationOptionsChanged
    case GoToMapForSharedEvent
    case GoToAccountDeepLink
    case PlayerLeaguesChanged // on join or leave
   
    // sharing/notifications
    case DisplayFeaturedEvent
    case DisplayFeaturedLeague

    func name() -> Notification.Name {
        return Notification.Name(self.rawValue)
    }
}

@available(iOS 10.0, *)
class NotificationService: NSObject {
    var scheduledEvents: [Balizinha.Event]?
    let disposeBag = DisposeBag()

    static var shared: NotificationService = NotificationService()
    var pushRequestFailed: Bool = false // allows us to disable the toggle button the first time it happens

    // LOCAL NOTIFICAITONS
    func refreshNotifications(_ events: [Balizinha.Event]?) {
        // store reference to events in case notifications are toggled
        self.scheduledEvents = events
        
        // remove old notifications
        self.clearAllNotifications()
        let userReceivesNotifications = PlayerService.shared.current.value?.notificationsEnabled ?? false
        guard userReceivesNotifications else { return }
        guard let events = events else { return }
        // reschedule event notifications
        for event in events {
            self.scheduleNotificationForEvent(event)
        }
        
    }
    
    func scheduleNotificationForEvent(_ event: Balizinha.Event) {
        //create local notification
        guard let startTime = event.startTime else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: "Are you ready?", arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: kEventNotificationMessage,
                                                                arguments: nil)
        content.userInfo = ["type": "eventReminder", "eventId": event.id]
        
        // Configure the trigger
        let date = startTime.addingTimeInterval(kEventNotificationIntervalSeconds)
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // Create the request object.
        let request = UNNotificationRequest(identifier: "EventReminder\(event.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func removeNotificationForEvent(_ event: Balizinha.Event) {
        let identifier = "EventReminder\(event.id)"
        self.removeNotification(id: identifier)
    }

    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func removeNotification(id: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (notificationRequests) in
            var identifiers: [String] = []
            for notification:UNNotificationRequest in notificationRequests {
                if notification.identifier == "identifierCancel" {
                    identifiers.append(notification.identifier)
                }
            }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
    
    func resetBadgeCount() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    // generates /playerTopics
    private var refreshedPlayerTopics: Bool = false
    func refreshAllPlayerTopicsOnce() {
        guard let player = PlayerService.shared.current.value else {
            return
        }
        guard !refreshedPlayerTopics else { return }
        print("PUSH: generating player topics for user \(player.id)")
        refreshedPlayerTopics = true
        let params: [String: Any] = ["userId": player.id]
        FirebaseAPIService().cloudFunction(functionName: "refreshAllPlayerTopics", params: params) { (result, error) in
            print("Result \(String(describing: result)) error \(String(describing: error))")
        }
    }
}

@available(iOS 10.0, *)
extension NotificationService {
    func registerForRemoteNotifications() {
        print("PUSH: registering for notifications")
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {[weak self] result, error in
                print("PUSH: request authorization result \(result) error \(String(describing: error))")
                guard let self = self else { return }

                if result, !AuthService.isAnonymous {
                    //
                    PlayerService.shared.current.asObservable().filterNil().take(1).subscribe(onNext: { (player) in
                        // store the fcm token on the player object
                        self.storeFCMToken()

                        // first time - refresh topics
                        self.refreshAllPlayerTopicsOnce()
                    }).disposed(by: self.disposeBag)
                } else {
                    self.pushRequestFailed = true
                }
        })

        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func storeFCMToken() {
        guard let player = PlayerService.shared.current.value else { return }
        InstanceID.instanceID().instanceID(handler: { (result, error) in
            print("PUSH: storeFCMToken with token \(String(describing: result?.token)) enabled \(player.notificationsEnabled)")
            if let token = result?.token, player.notificationsEnabled {
                player.fcmToken = token
            } else {
                player.fcmToken = "" // fixme: setting to nil doesn't change it. needs to delete ref instead
            }
        })
    }
    
    // User notification preference
    func toggleUserReceivesNotifications(_ enabled: Bool) {
        // set notification option on player
        guard let player = PlayerService.shared.current.value else {
            return
        }
        player.notificationsEnabled = enabled
//        let params: [String: Any] = ["userId": player.id, "pushEnabled": enabled]
//        FirebaseAPIService().cloudFunction(functionName: "refreshPlayerSubscriptions", params: params) { (result, error) in
//            print("Result \(String(describing: result)) error \(String(describing: error))")
//        }

        LoggingService.shared.log(event: LoggingEvent.PushNotificationsToggled, info: ["value": enabled])

        // toggle push notifications
        print("PUSH: using toggle to \(enabled ? "enabling" : "disabling") push notifications")
        storeFCMToken()
        
        // toggle/reschedule events
        self.refreshNotifications(self.scheduledEvents)
    }
}

// MARK: UNUserNotificationCenterDelegate
@available(iOS 10.0, *)
extension NotificationService: UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // FCM: when a user receives a push notification while foregrounded
        
        let userInfo = notification.request.content.userInfo
        
        print("PUSH: willPresent notification with userInfo \(userInfo)")
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        
        Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        // analytics
        LoggingService.shared.log(event: LoggingEvent.PushNotificationReceived, info: ["inApp": true])
        
        // Change this to your preferred presentation option
        completionHandler([])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // FCM: when a user clicks on a notification while in the background
        
        print("PUSH: didReceive response")
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        // analytics
        LoggingService.shared.log(event: LoggingEvent.PushNotificationReceived, info: ["inApp": false])

        completionHandler()
    }
    
}

@available(iOS 10.0, *)
extension NotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("PUSH: Firebase registration token: \(fcmToken)")
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("PUSH: Received data message: \(remoteMessage.appData)")
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("PUSH: Messaging did receive FCM token \(fcmToken)") // this can be received via instanceID().token
    }
}

