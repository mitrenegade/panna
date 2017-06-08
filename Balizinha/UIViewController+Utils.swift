//
//  UIViewController+Utils.swift
// Balizinha
//
//  Created by Bobby Ren on 5/8/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func simpleAlert(_ title: String, defaultMessage: String?, error: NSError?) {
        if let error = error {
            if let msg = error.userInfo["error"] as? String {
                self.simpleAlert(title, message: msg)
                return
            }
        }
        self.simpleAlert(title, message: defaultMessage ?? error.localizedDescription)
    }
    
    func simpleAlert(_ title: String, message: String?) {
        self.simpleAlert(title, message: message, completion: nil)
    }
    
    func simpleAlert(_ title: String, message: String?, completion: (() -> Void)?) {
        let alert: UIAlertController = UIAlertController.simpleAlert(title, message: message, completion: completion)
        self.present(alert, animated: true, completion: nil)
    }
    
    func appDelegate() -> AppDelegate {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate
    }
}

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

extension UIAlertController {
    class func simpleAlert(_ title: String, message: String?, completion: (() -> Void)?) -> UIAlertController {
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.view.tintColor = UIColor.black
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            print("cancel")
            if completion != nil {
                completion!()
            }
        }))
        return alert
    }
    
}
