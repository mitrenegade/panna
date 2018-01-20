//
//  ActionService.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/6/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

typealias actionUpdateHandler = (Action, _ visible: Bool) -> (Void)
class ActionService: NSObject {

    class func post(_ type: ActionType, eventId: String, message: String?) {
        // convenience function to encapsulate player loading and displayName for an action that is relevant to the current player
        guard let user = PlayerService.currentUser else { return }
        PlayerService.shared.withId(id: user.uid) { (player) in
            ActionService.post(type, userId: user.uid, username: player?.name ?? user.displayName, eventId: eventId, message: message)
        }
        
    }
    
    class func post(_ type: ActionType, userId: String?, username: String?, eventId: String, message: String?) {
        let baseRef = firRef.child("action") // this references the endpoint lotsports.firebase.com/action/
        let newObjectRef = baseRef.childByAutoId() // this generates an autoincremented event endpoint like lotsports.firebase.com/action/<uniqueId>
        var params: [String: Any] = ["type": type.rawValue, "event": eventId, "createdAt": Date().timeIntervalSince1970]
        if let userId = userId { // userId is almost always Auth.current
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
    
    class func delete(action: Action) {
        let actionId = action.id
         // instead of deleting the action, just set eventActions for this action to false
         // because eventAction observers don't recognize a delete vs a change/create
        guard let eventId = action.event else { return }
        let queryRef = firRef.child("eventActions").child(eventId)
        queryRef.updateChildValues([actionId: false])
    }
    
    func observeActions(forEvent event: Event, completion: @escaping actionUpdateHandler) {
        // returns all current events of a certain type. Returns as snapshot
        // only gets events once, and removes observer afterwards
        
        if AIRPLANE_MODE {
            return
        }
        
        // sort by time
        let queryRef = firRef.child("eventActions").child(event.id)
        
        // query for eventActions
        queryRef.observe(.value, with: { (snapshot) in
            print("observeActions snapshot: \(snapshot)")
            if let allObjects = snapshot.children.allObjects as? [DataSnapshot] {
                for actionDict in allObjects {
                    let actionId = actionDict.key
                    if let val = actionDict.value as? Bool {
                        
                        // query for the action
                        let actionQueryRef = firRef.child("action").child(actionId)
                        actionQueryRef.observeSingleEvent(of: .value, with: { (actionSnapshot) in
                            let action = Action(snapshot: actionSnapshot)
                            completion(action, val)
                        })
                    }
                }
            }
        })
        
        /*
         let queryRef = firRef.child("action").child(event.id)
         //        queryRef.queryOrdered(byChild: "event") // cannot be used to filter for events
        queryRef.observeSingleEvent(of: .value) { (snapshot: DataSnapshot!) in
            // this block is called for every result returned
            var results: [Action] = []
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                for actionDict: DataSnapshot in allObjects {
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
