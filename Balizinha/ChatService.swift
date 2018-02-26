//
//  ChatService.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/6/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

class ChatService: NSObject {
    class func createChat(eventId: String, message: String) {
        // convenience function to encapsulate player loading and displayName for an action that is relevant to the current player
        guard let user = PlayerService.currentUser else { return }
        PlayerService.shared.withId(id: user.uid) { (player) in
            post(userId: user.uid, username: player?.name ?? user.displayName, eventId: eventId, message: message)
        }
    }
    
    fileprivate class func post(userId: String, username: String?, eventId: String, message: String) {
        let baseRef = firRef.child("actions")
        FirebaseAPIService.getUniqueId { (id) in
            guard let uniqueId = id else { return }
            let newObjectRef = baseRef.child(uniqueId)

            var params: [String: Any] = ["type": ActionType.chat.rawValue, "event": eventId, "user": userId, "message": message]
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
}
