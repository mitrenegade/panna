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
import RxSwift

let kEventNotificationIntervalSeconds: TimeInterval = -3600
let kEventNotificationMessage: String = "You have an event in 1 hour!"
let kNotificationsDefaultsKey = "NotificationsDefaultsKey"

let gcmMessageIDKey = "gcm.message_id"

enum NotificationType: String {
    case LogoutSuccess
    case LoginSuccess
    case EventsChanged
    case PaymentContextChanged
    case GoToDonationForEvent
    case LocationOptionsChanged
    case GoToMapForSharedEvent
    
    func name() -> Notification.Name {
        return Notification.Name(self.rawValue)
    }
}

@available(iOS 10.0, *)
fileprivate var singleton: NotificationService?

@available(iOS 10.0, *)
class NotificationService: NSObject {
    var scheduledEvents: [Event]?
    let disposeBag = DisposeBag()

    static var shared: NotificationService {
        if let instance = singleton {
            return instance
        }
        singleton = NotificationService()
        return singleton!
    }
    
    // LOCAL NOTIFICAITONS
    func refreshNotifications(_ events: [Event]?) {
        // store reference to events in case notifications are toggled
        self.scheduledEvents = events
        
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
    
    func scheduleNotificationForEvent(_ event: Event) {
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
    
    func scheduleNotificationForDonation(_ event: Event) {
        //create local notification
        guard let endTime = event.endTime else { return }
        guard !event.userIsOrganizer else { return }
        let name = event.name ?? "the last game"
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: "Send Payment", arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: "Do you want to pay for playing in \(name)?", arguments: nil)
        content.userInfo = ["type": "donationReminder", "eventId": event.id]
        
        // Configure the trigger for a 7am wakeup.
        let date = endTime.addingTimeInterval(30*60)
//        let date = Date().addingTimeInterval(5)
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // Create the request object.
        let request = UNNotificationRequest(identifier: "DonationRequest\(event.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
        print("notification scheduled")
    }
    
    func removeNotificationForEvent(_ event: Event) {
        let identifier = "EventReminder\(event.id)"
        self.removeNotification(id: identifier)
    }

    func removeNotificationForDonation(_ event: Event) {
        let identifier = "DonationRequest\(event.id)"
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
}

@available(iOS 10.0, *)
extension NotificationService {
    func registerForRemoteNotifications() {
        print("PUSH: registering for notifications")
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {result, error in
                print("PUSH: request authorization result \(result) error \(String(describing: error))")
        })

        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func storeFCMToken(enabled: Bool) {
        PlayerService.shared.observedPlayer?.asObservable().take(1).subscribe(onNext: { (player) in
            if let fcmToken = InstanceID.instanceID().token(), enabled {
                print("PUSH: storing FCM token \(fcmToken)")
                player.fcmToken = fcmToken
            } else {
                print("PUSH: clearing FCM token")
                player.fcmToken = nil
            }
        }).disposed(by: disposeBag)
    }
    
    // User notification preference
    func userReceivesNotifications() -> Bool {
        guard let notificationsDefaultValue = UserDefaults.standard.object(forKey: kNotificationsDefaultsKey) else { return true }
        return (notificationsDefaultValue as AnyObject).boolValue
    }
    
    func toggleUserReceivesNotifications(_ enabled: Bool) {
        // set and store user preference in NSUserDefaults
        UserDefaults.standard.set(enabled, forKey: kNotificationsDefaultsKey)
        UserDefaults.standard.synchronize()

        // TODO: this does not disable existing topics
        // do some analytics
        LoggingService.shared.log(event: LoggingEvent.PushNotificationsToggled, info: ["value": enabled])

        // toggle push notifications
        print("PUSH: enabling push notifications: \(enabled)")
        storeFCMToken(enabled: enabled)
        
        // toggle/reschedule events
        self.refreshNotifications(self.scheduledEvents)
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
    
    func refreshEventTopics() {
        // TODO: move cached events to EventService
        // have allEvents, userEvents(current/past)
        // use userEvents(current) to refresh topics on toggle
    }
    
    func registerForEventNotifications(event: Event, subscribed: Bool) {
        let key = event.id
        var topic = "event" + key
        self.subscribeToTopic(topic: topic, subscribed: subscribed)
        print("\(subscribed ? "" : "Un-")Subscribing to event topic \(topic)")

        if event.userIsOrganizer {
            topic = "eventOwner" + key
            self.subscribeToTopic(topic: topic, subscribed: subscribed)
            print("\(subscribed ? "" : "Un-")Subscribing to event topic \(topic)")
        }
    }
    
    func registerForGeneralNotification(subscribed: Bool) {
        // register for general channel
        let topic = "general"
        self.subscribeToTopic(topic: topic, subscribed: subscribed)
        print("\(subscribed ? "" : "Un-")Subscribing to topic \(topic)")
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
        print("PUSH: Messaging did receive FCM token \(fcmToken)")
        
        // if user has push enabled but toggled notifications off in defaults, disable FCM token
        let enabled = userReceivesNotifications()
        storeFCMToken(enabled: enabled)
    }
}

