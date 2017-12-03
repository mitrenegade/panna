//
//  NotificationService.swift
// Balizinha
//
//  Created by Bobby Ren on 6/28/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import UserNotifications
import FirebaseMessaging
import Firebase

let kEventNotificationIntervalSeconds: TimeInterval = -3600
let kEventNotificationMessage: String = "You have an event in 1 hour!"
let kNotificationsDefaultsKey = "NotificationsDefaultsKey"

let gcmMessageIDKey = "gcm.message_id"

@available(iOS 10.0, *)
fileprivate var singleton: NotificationService?

@available(iOS 10.0, *)
class NotificationService: NSObject {
    var pushDeviceToken: Data?
    var scheduledEvents: [Event]?

    static var shared: NotificationService {
        if let instance = singleton {
            return instance
        }
        singleton = NotificationService()
        return singleton!
    }
    
    // LOCAL NOTIFICAITONS
    class func refreshNotifications(_ events: [Event]?) {
        // store reference to events in case notifications are toggled
        self.shared.scheduledEvents = events
        
        // remove old notifications
        self.clearAllNotifications()
        
        guard self.userReceivesNotifications() else { return }
        guard let events = events else { return }
        // reschedule event notifications
        for event in events {
            self.scheduleNotificationForEvent(event)
            self.scheduleNotificationForDonation(event)
        }
        
    }
    
    class func scheduleNotificationForEvent(_ event: Event) {
        //create local notification
        guard let startTime = event.startTime else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: "Are you ready?", arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: kEventNotificationMessage,
                                                                arguments: nil)
        content.userInfo = ["type": "eventReminder", "eventId": event.id]
        
        // Configure the trigger
        let date = startTime.addingTimeInterval(kEventNotificationIntervalSeconds)
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // Create the request object.
        let request = UNNotificationRequest(identifier: "EventReminder\(event.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    class func scheduleNotificationForDonation(_ event: Event) {
        //create local notification
        guard let endTime = event.endTime else { return }
        guard !event.userIsOrganizer else { return }
        let name = event.name ?? "the last game"
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: "Donate", arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: "Do you want to contribute for \(name)?", arguments: nil)
        content.userInfo = ["type": "donationReminder", "eventId": event.id]
        
        // Configure the trigger for a 7am wakeup.
        let date = endTime.addingTimeInterval(30*60)
//        let date = Date().addingTimeInterval(5)
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // Create the request object.
        let request = UNNotificationRequest(identifier: "DonationRequest\(event.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
        print("notification scheduled")
    }
    
    class func removeNotificationForEvent(_ event: Event) {
        let identifier = "EventReminder\(event.id)"
        self.removeNotification(id: identifier)
    }

    class func removeNotificationForDonation(_ event: Event) {
        let identifier = "DonationRequest\(event.id)"
        self.removeNotification(id: identifier)
    }

    class func clearAllNotifications() {
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    class func removeNotification(id: String) {
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
    
}

@available(iOS 10.0, *)
extension NotificationService {
    class func enablePush(_ deviceToken: Data, enabled: Bool) {
        let token: String = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("PUSH: registered for push with token \(token)")

        PlayerService.shared.observedPlayer?.asObservable().take(1).subscribe(onNext: { (player) in
            player.deviceToken = token
        })
        self.shared.pushDeviceToken = deviceToken
    }
    
    // User notification preference
    class func userReceivesNotifications() -> Bool {
        guard let notificationsDefaultValue = UserDefaults.standard.object(forKey: kNotificationsDefaultsKey) else { return true }
        return (notificationsDefaultValue as AnyObject).boolValue
    }
    
    class func toggleUserReceivesNotifications(_ enabled: Bool) {
        // set and store user preference in NSUserDefaults
        UserDefaults.standard.set(enabled, forKey: kNotificationsDefaultsKey)
        UserDefaults.standard.synchronize()
        
        // toggle push notifications
        if let deviceToken = self.shared.pushDeviceToken {
            self.enablePush(deviceToken, enabled: enabled)
        }
        else {
            // reregister
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil))
        }
        
        // toggle/reschedule events
        self.refreshNotifications(self.shared.scheduledEvents)
    }
}

// PUSH Notifications for pubsub
@available(iOS 10.0, *)
extension NotificationService {
    fileprivate func subscribeToTopic(topic: String, subscribed: Bool) {
        if subscribed {
            Messaging.messaging().subscribe(toTopic: topic)
        } else {
            Messaging.messaging().unsubscribe(fromTopic: topic)
        }
    }
    
    func registerForEventNotifications(event: Event, subscribed: Bool) {
        let key = event.id
        var topic = "event" + key
        if event.userIsOrganizer {
            topic = "eventOwner" + key
        }
        print("\(subscribed ? "" : "Un-")Subscribing to event topic \(topic)")
        self.subscribeToTopic(topic: topic, subscribed: subscribed)
    }
}

// MARK: AppDelegate calls
@available(iOS 10.0, *)
extension NotificationService {
    func didRegisterForRemoteNotifications(deviceToken: Data) {
        
        // https://firebase.google.com/docs/cloud-messaging/ios/client
        // this is for topics
        Messaging.messaging().apnsToken = deviceToken
        
        // this is used for regular apn push, if a push notification was sent with a token
        if let refreshedToken = InstanceID.instanceID().token() {
            print("PUSH: InstanceID token: \(refreshedToken)")
            NotificationService.enablePush(deviceToken, enabled:true)
        }
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
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
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
        
        completionHandler()
    }
    
}
