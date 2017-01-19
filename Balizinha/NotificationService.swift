//
//  NotificationService.swift
//  LotSportz
//
//  Created by Bobby Ren on 6/28/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

let kEventNotificationIntervalSeconds: TimeInterval = -3600
let kEventNotificationMessage: String = "You have an event in 1 hour!"
let kNotificationsDefaultsKey = "NotificationsDefaultsKey"

var notificationServiceSingleton: NotificationService?

class NotificationService: NSObject {
    var pushDeviceToken: Data?
    var scheduledEvents: [Event]?

    class func sharedInstance() -> NotificationService {
        if let instance = notificationServiceSingleton {
            return instance
        }
        notificationServiceSingleton = NotificationService()
        return notificationServiceSingleton!
    }
    
    // LOCAL NOTIFICAITONS
    class func refreshNotifications(_ events: [Event]?) {
        // store reference to events in case notifications are toggled
        self.sharedInstance().scheduledEvents = events
        
        // remove old notifications
        self.clearAllNotifications()
        
        guard self.userReceivesNotifications() else { return }
        guard let events = events else { return }
        // reschedule event notifications
        for event in events {
            //create local notification
            let notification = UILocalNotification()
            notification.fireDate = event.startTime().addingTimeInterval(kEventNotificationIntervalSeconds) as Date
            
            notification.alertBody = kEventNotificationMessage
            UIApplication.shared.scheduleLocalNotification(notification)
        }
        
    }
    
    class func scheduleNotificationForEvent(_ event: Event) {
        let notification = UILocalNotification()
        notification.fireDate = event.startTime().addingTimeInterval(kEventNotificationIntervalSeconds) as Date
        notification.alertBody = kEventNotificationMessage
        UIApplication.shared.scheduleLocalNotification(notification)
    }
    
    class func clearAllNotifications() {
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    // PUSH NOTIFICATIONS
    class func registerForPushNotifications(_ deviceToken: Data, enabled: Bool) {
        let installation = PFInstallation.current()
        installation!.setDeviceTokenFrom(deviceToken)
        let channel: String = "eventsGlobal"
        if enabled {
            installation!.addUniqueObject(channel, forKey: "channels") // subscribe to global channel
        }
        else {
            installation!.remove(channel, forKey: "channels")
        }
        installation!.saveInBackground()
        
        let channels = installation!.object(forKey: "channels")
        print("installation registered for remote notifications: token \(deviceToken) channel \(channels)")
        
        self.sharedInstance().pushDeviceToken = deviceToken
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
        if let deviceToken = self.sharedInstance().pushDeviceToken {
            self.registerForPushNotifications(deviceToken, enabled: enabled)
        }
        else {
            // reregister
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil))
        }
        
        // toggle/reschedule events
        self.refreshNotifications(self.sharedInstance().scheduledEvents)
    }
}
