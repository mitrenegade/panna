//
//  NotificationService.swift
//  LotSportz
//
//  Created by Bobby Ren on 6/28/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

let kEventNotificationIntervalSeconds: NSTimeInterval = -3600
let kEventNotificationMessage: String = "You have an event in 1 hour!"
let kNotificationsDefaultsKey = "NotificationsDefaultsKey"

var notificationServiceSingleton: NotificationService?

class NotificationService: NSObject {
    var pushDeviceToken: NSData?
    var scheduledEvents: [Event]?

    class func sharedInstance() -> NotificationService {
        if let instance = notificationServiceSingleton {
            return instance
        }
        notificationServiceSingleton = NotificationService()
        return notificationServiceSingleton!
    }
    
    // LOCAL NOTIFICAITONS
    class func refreshNotifications(events: [Event]?) {
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
            notification.fireDate = event.startTime().dateByAddingTimeInterval(kEventNotificationIntervalSeconds)
            
            notification.alertBody = kEventNotificationMessage
            UIApplication.sharedApplication().scheduleLocalNotification(notification)
        }
        
    }
    
    class func scheduleNotificationForEvent(event: Event) {
        let notification = UILocalNotification()
        notification.fireDate = event.startTime().dateByAddingTimeInterval(kEventNotificationIntervalSeconds)
        notification.alertBody = kEventNotificationMessage
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    class func clearAllNotifications() {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
    }
    
    // PUSH NOTIFICATIONS
    class func registerForPushNotifications(deviceToken: NSData, enabled: Bool) {
        let installation = PFInstallation.currentInstallation()
        installation!.setDeviceTokenFromData(deviceToken)
        let channel: String = "eventsGlobal"
        if enabled {
            installation!.addUniqueObject(channel, forKey: "channels") // subscribe to global channel
        }
        else {
            installation!.removeObject(channel, forKey: "channels")
        }
        installation!.saveInBackground()
        
        let channels = installation!.objectForKey("channels")
        print("installation registered for remote notifications: token \(deviceToken) channel \(channels)")
        
        self.sharedInstance().pushDeviceToken = deviceToken
    }
    
    // User notification preference
    class func userReceivesNotifications() -> Bool {
        guard let notificationsDefaultValue = NSUserDefaults.standardUserDefaults().objectForKey(kNotificationsDefaultsKey) else { return true }
        return notificationsDefaultValue.boolValue
    }
    
    class func toggleUserReceivesNotifications(enabled: Bool) {
        // set and store user preference in NSUserDefaults
        NSUserDefaults.standardUserDefaults().setObject(enabled, forKey: kNotificationsDefaultsKey)
        NSUserDefaults.standardUserDefaults().synchronize()
        
        // toggle push notifications
        if let deviceToken = self.sharedInstance().pushDeviceToken {
            self.registerForPushNotifications(deviceToken, enabled: enabled)
        }
        else {
            // reregister
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Sound, .Alert, .Badge], categories: nil))
        }
        
        // toggle/reschedule events
        self.refreshNotifications(self.sharedInstance().scheduledEvents)
    }
}
