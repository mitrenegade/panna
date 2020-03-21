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
import RenderCloud

let gcmMessageIDKey = "gcm.message_id"

@available(iOS 10.0, *)
class NotificationService: NSObject {
    var scheduledEvents: [Balizinha.Event]?
    let disposeBag = DisposeBag()

    static var shared: NotificationService = NotificationService()
    var pushRequestFailed: Bool = false // allows us to disable the toggle button the first time it happens

    // LOCAL NOTIFICAITONS
    func refreshNotifications(_ events: [Balizinha.Event]?) {
        // store reference to events in case notifications are toggled
        scheduledEvents = events
        
        // remove old notifications
        clearAllNotifications()
        let userReceivesNotifications = PlayerService.shared.current.value?.notificationsEnabled ?? false
        guard userReceivesNotifications else { return }
        guard let events = events else { return }
        // reschedule event notifications
        for event in events {
            scheduleLocalNotifications(for: event)
        }
        
    }
    
    private func nameStringForEventReminder(_ event: Balizinha.Event) -> String {
        if let name = event.name {
            return name + " starts"
        } else {
            return "You have an event"
        }
    }
    
    private func timeStringForEventReminder(_ event: Balizinha.Event, interval: TimeInterval) -> String {
        if interval < 3600 {
            return "soon!"
        } else if interval == 3600 {
            return "in an hour!"
        } else if interval == 7200 {
            return "in two hours!"
        } else {
            if let time = event.startTime {
                return "at " + time.timeStringForPicker() + "."
            } else {
                return "sometime." // this hsould never happen
            }
        }
    }
    
    internal func eventReminderString(_ event: Balizinha.Event, interval: TimeInterval) -> String {
        let nameString: String = nameStringForEventReminder(event)
        let timeString: String = timeStringForEventReminder(event, interval: interval)
        return "\(nameString) \(timeString)"
    }
    
    private func scheduleReminderForUpcomingEvent(_ event: Balizinha.Event) {
        //create local notification
        guard let startTime = event.startTime else { return }
        var interval = SettingsService.eventReminderInterval
        var date = startTime.addingTimeInterval(-1 * interval)
        if date.timeIntervalSinceNow < 0 {
            interval = SettingsService.eventReminderIntervalShort
            date = startTime.addingTimeInterval(-1 * interval)
        }

        let content = UNMutableNotificationContent()
        let message = eventReminderString(event, interval: interval)
        content.title = NSString.localizedUserNotificationString(forKey: "Are you ready?", arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: message, arguments: nil)
        content.userInfo = ["type": "eventReminder", "eventId": event.id]
        
        // Configure the trigger
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // Create the request object.
        let request = UNNotificationRequest(identifier: "EventReminder\(event.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private func scheduleNextReminderAfterEvent(_ event: Balizinha.Event) {
        //create local notification
        guard let endTime = event.endTime else { return }
        let interval = SettingsService.eventPromptInterval
        let content = UNMutableNotificationContent()
        let message = "Hope you can join for the next event."
        content.title = NSString.localizedUserNotificationString(forKey: "Thanks for coming!", arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: message, arguments: nil)
        content.userInfo = ["type": "nextEventPrompt", "eventId": event.id]
        
        // Configure the trigger
        let date = endTime.addingTimeInterval(interval)
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // Create the request object.
        let request = UNNotificationRequest(identifier: "NextEventPrompt\(event.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    private func scheduleVideoLinkReminder(_ event: Balizinha.Event) {
        guard let url = event.validVideoUrl else { return }
        //create local notification which opens the video
        guard let startTime = event.startTime else { return }
        let date = Date() + 5

        let content = UNMutableNotificationContent()
        let message = "Event starting at \(url.absoluteString)"
        content.title = NSString.localizedUserNotificationString(forKey: "Join video link?", arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: message, arguments: nil)
        content.userInfo = ["type": "videoLinkReminder", "eventId": event.id]
        
        // Configure the trigger
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // Create the request object.
        let request = UNNotificationRequest(identifier: "VideoLink\(event.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func scheduleLocalNotifications(for event: Balizinha.Event) {
        scheduleReminderForUpcomingEvent(event)
        scheduleNextReminderAfterEvent(event)
        scheduleVideoLinkReminder(event)
    }

    func removeNotificationsForEvent(_ event: Balizinha.Event) {
        let identifier = "EventReminder\(event.id)"
        removeNotification(id: identifier)
        let identifier2 = "NextEventPrompt\(event.id)"
        removeNotification(id: identifier2)
        let identifier3 = "VideoLinkPrompt\(event.id)"
        removeNotification(id: identifier3)
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
        RenderAPIService().cloudFunction(functionName: "refreshAllPlayerTopics", params: params) { (result, error) in
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
                    PlayerService.shared.current.asObservable().filterNil().take(1).subscribe(onNext: { [weak self] (player) in
                        // store the fcm token on the player object
                        self?.storeFCMToken()

                        // first time - refresh topics
                        self?.refreshAllPlayerTopicsOnce()
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
            if let token = result?.token {
                player.fcmToken = token
            } else {
                player.fcmToken = "" // fixme: setting to nil doesn't change it. needs to delete ref instead
            }
        })
    }
    
    // User notification preference
    func toggleUserReceivesNotifications(_ enabled: Bool, completion: ((Error?) -> Void)?) {
        // set notification option on player
        guard let player = PlayerService.shared.current.value else {
            return
        }
        let params: [String: Any] = ["userId": player.id, "pushEnabled": enabled]
        RenderAPIService().cloudFunction(functionName: "updateUserNotificationsEnabled", params: params) { (result, error) in
            var userInfo: [String: Any] = ["value": enabled]
            if let error = error {
                userInfo["error"] = error.localizedDescription
            }
            LoggingService.shared.log(event: LoggingEvent.PushNotificationsToggled, info: userInfo)
            completion?(error)
        }
        
        // toggle/reschedule events
        refreshNotifications(scheduledEvents)
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
        // data looks like:
        /*
        [AnyHashable("google.c.a.e"): 1, AnyHashable("aps"): {
            alert =     {
                body = "Philly Phanatic said: test1";
                title = "Event chat";
            };
            badge = 1;
            sound = default;
            }, AnyHashable("gcm.message_id"): 0:1554433506759149%8923ce3e8923ce3e]
        */
        
        print("PUSH: didReceive response. userInfo: \(userInfo)")
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // analytics
        LoggingService.shared.log(event: LoggingEvent.PushNotificationReceived, info: ["inApp": false])
        handle(notification: userInfo)
        
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

extension NotificationService {
    func handle(notification: [AnyHashable: Any]) {
        guard let type = notification["type"] as? String else { return }
        if let actionType = ActionType(rawValue: type) {
            // handle supported actions
            switch actionType {
            case .chat, .joinEvent, .createEvent:
                if let eventId = notification["eventId"] {
                    notify(.DisplayFeaturedEvent, object: nil, userInfo: ["eventId": eventId])
                }
            default:
                break
            }
        } else if type == "leagueChat" {
            // handle league chat
            if let leagueId = notification["leagueId"] {
                notify(.DisplayFeaturedLeague, object: nil, userInfo: ["leagueId": leagueId])
            }
        } else if type == "cancelEvent" {
            // handle event cancellation
            notify(NotificationType.EventsChanged, object: nil, userInfo: nil)
        }
    }
}
