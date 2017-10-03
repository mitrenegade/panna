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
fileprivate let GENERIC_CHAT = "..."
fileprivate let GENERIC_USERNAME = "A player"
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
    
    var username: String? {
        // makes it easier to generate displayString
        get {
            if let username = self.dict["username"] as? String {
                return username
            }
            return nil
        }
        set {
            self.dict["username"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var event: String? { // if an action is directly related to an event
        get {
            return self.dict["event"] as? String
        }
        set {
            self.dict["event"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

    var message: String? {
        get {
            return self.dict["message"] as? String
        }
        set {
            self.dict["message"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var visible: Bool { // whether an action should appear in the feed
        get {
            return self.dict["visible"] as? Bool ?? false
        }
        set {
            self.dict["visible"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var createdAt: Date? {
        if let timeInterval = self.dict["createdAt"] as? TimeInterval {
            return Date(timeIntervalSince1970: timeInterval)
        }
        return nil
    }
}

extension Action {
    var displayDate: String {
        let createdAt: Date
        if let val = self.dict["createdAt"] as? TimeInterval {
            createdAt = Date(timeIntervalSince1970: val)
        }
        else {
            return "65 Billion BC"
        }
        
        return createdAt.dateString()
    }
    
    var displayString: String {
        let uid = self.user ?? ""
        let userString = self.userIsOrganizer ? "You" : (self.username ?? (PlayerService.cachedNames[uid] ?? GENERIC_USERNAME) )
        switch self.type {
        case .chat:
            return userString + " said: " + (self.message ?? GENERIC_CHAT)
        case .createEvent:
            return userString + " created this event at " + self.displayDate
        case .joinEvent:
            return userString + " joined this event"
        case .leaveEvent:
            return userString + " left this event"
        default:
            // system message
            return "Admin says: hi"
        }
    }
    
    
    var userIsOrganizer: Bool {
        guard let owner = self.user else { return false }
        guard let user = firAuth.currentUser else { return false }
        
        return user.uid == owner
    }
}
