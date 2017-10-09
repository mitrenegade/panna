//
//  NSObject+Utils.swift
//  Balizinha
//
//  Created by Bobby Ren on 10/9/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation

extension NSObject {
    
    // MARK: - Notifications
    func listenFor(_ notificationName: String, action: Selector, object: AnyObject?) {
        NotificationCenter.default.addObserver(self, selector: action, name: NSNotification.Name(rawValue: notificationName), object: object)
    }
    
    func stopListeningFor(_ notificationName: String) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: notificationName), object: nil)
    }
    
    func notify(_ notificationName: String, object: AnyObject?, userInfo: [AnyHashable: Any]?) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: notificationName), object: object, userInfo: userInfo)
    }
    
    func listenFor(_ notification: NotificationType, action: Selector, object: AnyObject?) {
        NotificationCenter.default.addObserver(self, selector: action, name: notification.name(), object: object)
    }
    
    func stopListeningFor(_ notification: NotificationType) {
        NotificationCenter.default.removeObserver(self, name: notification.name(), object: nil)
    }
    
    func notify(_ notification: NotificationType, object: AnyObject?, userInfo: [AnyHashable: Any]?) {
        NotificationCenter.default.post(name: notification.name(), object: object, userInfo: userInfo)
    }
}

