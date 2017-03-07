//
//  Constants.swift
// Balizinha
//
//  Created by Bobby Ren on 5/8/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Foundation

let leaveColor = UIColor(red: 253/256.0, green: 172/256.0, blue: 146/256.0, alpha: 1.0)
let joinColor = UIColor(red: 28/256.0, green: 71/256.0, blue: 131/256.0, alpha: 1.0)

var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

enum NotificationType: String {
    case LogoutSuccess
    case LoginSuccess
    case EventsChanged
    
    func name() -> Notification.Name {
        return Notification.Name(self.rawValue)
    }
}

var TESTING = false
var AIRPLANE_MODE = false

var FEATURE_FLAGS: [String: Any] = [
    "SoccerOnly": true // for Balizinha, only sport is soccer
    ]
