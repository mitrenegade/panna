//
//  Action.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/6/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

enum ActionType: String {
    case chat
    case createEvent
    case joinEvent
    case leaveEvent
    case systemMessage
}

fileprivate let GENERIC_MESSAGE = " is in this game"
class Action: FirebaseBaseModel {
    var type: ActionType {
        get {
            if let typeString = self.dict["type"] as? String, let actionType = ActionType(rawValue: typeString) {
                return actionType
            }
            return .systemMessage
        }
        set {
            self.dict["type"] = newValue.rawValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var user: String? {
        // if user is nil, then it should be a system message
        get {
            return self.dict["user"] as? String
        }
        set {
            self.dict["user"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var event: String {
        get {
            return self.dict["event"] as? String ?? "" // invalid event ids will be filtered out
        }
        set {
            self.dict["event"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

    var message: String {
        get {
            return self.dict["message"] as? String ?? GENERIC_MESSAGE
        }
        set {
            self.dict["message"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
}
