//
//  ActionService.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/6/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//
// similar to parse logging

import UIKit
import Firebase

typealias actionUpdateHandler = ([Action]) -> (Void)
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
    
    func listenForActions(event: Event, completion: @escaping actionUpdateHandler) {
        // returns all current events of a certain type. Returns as snapshot
        // only gets events once, and removes observer afterwards
        let queryRef = firRef.child("action")//childByAppendingPath("events") // this creates a query on the endpoint lotsports.firebase.com/events/
        
        // sort by time
        queryRef.queryOrdered(byChild: "createdAt")
        
        // filter for type
        // do query
        var handle: UInt = 0
        handle = queryRef.observe(.value) { (snapshot: FIRDataSnapshot!) in
            // this block is called for every result returned
            var results: [Action] = []
            if let allObjects =  snapshot.children.allObjects as? [FIRDataSnapshot] {
                for actionDict: FIRDataSnapshot in allObjects {
                    let action = Action(snapshot: actionDict)
                    results.append(action)
                }
            }
            print("getEvents results count: \(results.count)")
            completion(results)
        }
    }

}
