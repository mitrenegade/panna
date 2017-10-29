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

let kEventNotificationIntervalSeconds: TimeInterval = -3600
let kEventNotificationMessage: String = "You have an event in 1 hour!"
let kNotificationsDefaultsKey = "NotificationsDefaultsKey"

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
    class func registerForPushNotifications(_ deviceToken: Data, enabled: Bool) {
        let token: String = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("registered for push with token \(token)")

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
            self.registerForPushNotifications(deviceToken, enabled: enabled)
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
    fileprivate func subscribeToTopic(topic: String) {
        Messaging.messaging().subscribe(toTopic: topic)
    }
    
    func registerForEventNotifications(event: Event) {
        let key = event.id
        let topic = "event:" + key
        self.subscribeToTopic(topic: topic)
    }
    
    func sendForDelete(event: Event) {
        
    }
    
    fileprivate func sendNotificationHelper() {
        
    }
}
