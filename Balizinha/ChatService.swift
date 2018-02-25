//
//  ChatService.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/6/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

typealias actionUpdateHandler = (Action, _ visible: Bool) -> (Void)
class ChatService: NSObject {

    fileprivate class func getUniqueId(completion: @escaping ((String?)->())) {
        let method = "POST"
        FirebaseAPIService.shared.cloudFunction(functionName: "getUniqueId", method: method, params: nil) { (result, error) in
            if let result = result as? [String: String], let id = result["id"] {
                completion(id)
                return
            }
            completion(nil)
        }
    }

    class func post(eventId: String, message: String) {
        // convenience function to encapsulate player loading and displayName for an action that is relevant to the current player
        guard let user = PlayerService.currentUser else { return }
        PlayerService.shared.withId(id: user.uid) { (player) in
            post(userId: user.uid, username: player?.name ?? user.displayName, eventId: eventId, message: message)
        }
    }
    
    class func post(userId: String, username: String?, eventId: String, message: String) {
        
        let baseRef = firRef.child("action")
        getUniqueId { (id) in
            guard let uniqueId = id else { return }
            let newObjectRef = baseRef.child(uniqueId)

            // Todo: remove createdAt, make sure it gets created on the server
            var params: [String: Any] = ["type": ActionType.chat.rawValue, "event": eventId, "createdAt": Date().timeIntervalSince1970, "user": userId, "message": message]
            if let username = username {
                params["username"] = username
            }
            
            newObjectRef.setValue(params) { (error, ref) in
                print("Chat created for user \(userId) event \(eventId) message \(message)")
                
                guard error == nil else { return }
                
                // add the entry [actionId: true] to eventActions/eventId
                // should not need a transaction since we are not changing existing values under /eventId
                let eventActionRef = firRef.child("eventActions").child(eventId)
                let actionId = ref.key
                let params: [String: Any] = [actionId: true]
                // TODO: remove this, create this on server
                eventActionRef.updateChildValues(params, withCompletionBlock: { (error, ref) in
                    print("ref \(ref)")
                })
            }
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
