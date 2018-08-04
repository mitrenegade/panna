//
//  ActionService.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/6/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseCommunity
import Balizinha

typealias actionUpdateHandler = (Action, _ visible: Bool) -> (Void)
class ActionService: NSObject {
    class func delete(action: Action) {
        let actionId = action.id
         // instead of deleting the action, just set eventActions for this action to false
         // because eventAction observers don't recognize a delete vs a change/create
        guard let eventId = action.event else { return }
        let queryRef = firRef.child("eventActions").child(eventId)
        queryRef.updateChildValues([actionId: false])
    }
    
    func observeActions(forEvent event: Balizinha.Event, completion: @escaping actionUpdateHandler) {
        // returns all current events of a certain type. Returns as snapshot
        // only gets events once, and removes observer afterwards
        
        if AIRPLANE_MODE {
            return
        }
        
        // sort by time
        let queryRef = firRef.child("eventActions").child(event.id)
        
        // query for eventActions
        queryRef.observe(.value, with: { (snapshot) in
            if let allObjects = snapshot.children.allObjects as? [DataSnapshot] {
                for actionDict in allObjects {
                    let actionId = actionDict.key
                    if let val = actionDict.value as? Bool {
                        
                        // query for the action
                        let actionQueryRef = firRef.child("actions").child(actionId)
                        actionQueryRef.observeSingleEvent(of: .value, with: { (actionSnapshot) in
                            if actionSnapshot.exists() {
//                                print("observeActions snapshot: \(actionSnapshot)")
                                let action = Action(snapshot: actionSnapshot)
                                completion(action, val)
                            }
                        })
                    }
                }
            }
        })
    }

}
