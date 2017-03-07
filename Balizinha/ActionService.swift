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

typealias actionUpdateHandler = (Action) -> (Void)
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
        
        // sort by time
        let queryRef = firRef.child("eventActions").child(event.id)
        
        // query for eventActions
        queryRef.observe(.value, with: { (snapshot) in
            print("snapshot: \(snapshot)")
            if let allObjects = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for actionDict in allObjects {
                    let actionId = actionDict.key
                    if let val = actionDict.value as? Bool, val == true {
                        
                        // query for the action
                        let actionQueryRef = firRef.child("action").child(actionId)
                        actionQueryRef.observeSingleEvent(of: .value, with: { (actionSnapshot) in
                            let action = Action(snapshot: actionSnapshot)
                            completion(action)
                        })
                    }
                }
            }
        })
        
        /*
         let queryRef = firRef.child("action").child(event.id)
         //        queryRef.queryOrdered(byChild: "event") // cannot be used to filter for events
        queryRef.observeSingleEvent(of: .value) { (snapshot: FIRDataSnapshot!) in
            // this block is called for every result returned
            var results: [Action] = []
            if let allObjects =  snapshot.children.allObjects as? [FIRDataSnapshot] {
                for actionDict: FIRDataSnapshot in allObjects {
                    if let eventId = actionDict.childSnapshot(forPath: "event").value as? String, eventId == event.id {
                        let action = Action(snapshot: actionDict)
                        results.append(action)
                        print(action.event)
                    }
                }
            }
            print("loadedActions results count: \(results.count)")
            completion(results, controller)
        }
        */
    }

}
