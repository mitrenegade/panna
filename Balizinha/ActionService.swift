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

typealias actionUpdateHandler = ([Action], EventActionsViewController) -> (Void)
class ActionService: NSObject {
    class func post(_ type: ActionType, userId: String?, username: String?, eventId: String, message: String?) {
        let baseRef = firRef.child("action") // this references the endpoint lotsports.firebase.com/action/
        let newObjectRef = baseRef.childByAutoId() // this generates an autoincremented event endpoint like lotsports.firebase.com/action/<uniqueId>
        var params: [String: Any] = ["type": type.rawValue, "event": eventId, "createdAt": Date().timeIntervalSince1970]
        if let userId = userId { // userId is almost always FIRAuth.current
            params["user"] = userId
        }
        if let username = username {
            params["username"] = username
        }
        if let message = message {
            params["message"] = message
        }
        
        newObjectRef.setValue(params) { (error, ref) in
            print("post created for \(type.rawValue) user \(userId) event \(eventId) message \(message)")
            
            guard error == nil else { return }
            
            // add the entry [actionId: true] to eventActions/eventId
            // should not need a transaction since we are not changing existing values under /eventId
            let eventActionRef = firRef.child("eventActions").child(eventId)
            let actionId = ref.key
            let params: [String: Any] = [actionId: true]
            eventActionRef.updateChildValues(params, withCompletionBlock: { (error, ref) in
                print("ref \(ref)")
            })
        }
    }
    
    func listenForActions(event: Event, controller: EventActionsViewController, completion: @escaping actionUpdateHandler) {
        // returns all current events of a certain type. Returns as snapshot
        // only gets events once, and removes observer afterwards
        let queryRef = firRef.child("action")//childByAppendingPath("events") // this creates a query on the endpoint lotsports.firebase.com/events/
        
        // sort by time
//        queryRef.queryEqual(toValue: event.id, childKey: "event")
        queryRef.queryOrdered(byChild: "event").queryEqual(toValue: "-KebA1X-9WbR0Sjh0NfF")
//        queryRef.queryEqual(toValue: "joinEvent", childKey: "type")
        
        // filter for type
        // do query
        var handle: UInt = 0
        queryRef.observeSingleEvent(of: .value) { (snapshot: FIRDataSnapshot!) in
            // this block is called for every result returned
            var results: [Action] = []
            if let allObjects =  snapshot.children.allObjects as? [FIRDataSnapshot] {
                for actionDict: FIRDataSnapshot in allObjects {
                    let action = Action(snapshot: actionDict)
                    results.append(action)
                    print(action.event)
                }
            }
            print("loadedActions results count: \(results.count)")
            completion(results, controller)
        }
    }

}
