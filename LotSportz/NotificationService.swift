//
//  NotificationService.swift
//  LotSportz
//
//  Created by Bobby Ren on 6/28/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

let kEventNotificationIntervalSeconds: NSTimeInterval = -3600
let kEventNotificationMessage: String = "You have an event in 1 hour!"

class NotificationService: NSObject {
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
}
