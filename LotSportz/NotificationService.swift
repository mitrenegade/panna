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

class NotificationService: NSObject {
    
    // LOCAL NOTIFICAITONS
    class func refreshNotifications(events: [Event]) {
        self.clearAllNotifications()
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
        installation.setDeviceTokenFromData(deviceToken)
        let channel: String = "eventsGlobal"
        if enabled {
            installation.addUniqueObject(channel, forKey: "channels") // subscribe to global channel
        }
        else {
            installation.removeObject(channel, forKey: "channels")
        }
        installation.saveInBackground()
        
        let channels = installation.objectForKey("channels")
        print("installation registered for remote notifications: token \(deviceToken) channel \(channels)")
    }
}
