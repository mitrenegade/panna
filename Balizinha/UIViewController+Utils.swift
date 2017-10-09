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
        self.simpleAlert(title, message: defaultMessage ?? error?.localizedDescription)
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
