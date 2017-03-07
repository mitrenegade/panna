//
//  ActionService.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/6/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//
// similar to parse logging

import UIKit

class ActionService: NSObject {
    class func post(_ type: ActionType, userId: String?, eventId: String, message: String?) {
        let baseRef = firRef.child("action") // this references the endpoint lotsports.firebase.com/action/
        let newObjectRef = baseRef.childByAutoId() // this generates an autoincremented event endpoint like lotsports.firebase.com/action/<uniqueId>
        var params: [String: Any] = ["type": type.rawValue, "event": eventId, "createdAt": Date().timeIntervalSince1970]
        if let userId = userId { // userId is almost always FIRAuth.current
            params["user"] = userId
        }
        if let message = message {
            params["message"] = message
        }
        
        newObjectRef.setValue(params) { (error, ref) in
            print("post created for \(type.rawValue) user \(userId) event \(eventId) message \(message)")
        }
    }
}
