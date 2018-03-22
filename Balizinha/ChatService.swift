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
        guard let user = AuthService.currentUser else { return }
        PlayerService.shared.withId(id: user.uid) { (player) in
            post(userId: user.uid, eventId: eventId, message: message)
        }
    }
    
    fileprivate class func post(userId: String, eventId: String, message: String) {
        let baseRef = firRef.child("actions")
        let id = FirebaseAPIService.uniqueId()
        let newObjectRef = baseRef.child(id)

        var params: [String: Any] = ["type": ActionType.chat.rawValue, "event": eventId, "user": userId, "message": message]
        
        newObjectRef.setValue(params) { (error, ref) in
            print("Chat created for user \(userId) event \(eventId) message \(message)")
        }
    }
}
