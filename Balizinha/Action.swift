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
    case donation
    case payForEvent
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
    
    var userId: String? {
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
}


class ActionViewModel {
    var action: Action
    var event: Event?
    
    init(action: Action) {
        self.action = action
        switch action.type {
        case .createEvent, .joinEvent, .leaveEvent, .payForEvent:
            if let eventId = action.event {
                EventService.shared.withId(id: eventId, completion: { [weak self] (event) in
                    self?.event = event
                })
            }
        default:
            return
        }
    }
    
    var displayDate: String {
        if let date = action.createdAt {
            return date.dateString()
        }
        return "65 Billion BC"
    }
    
    var eventName: String {
        return event?.name ?? "this event"
    }
    
    var displayString: String {
        let userString = self.userIsOrganizer ? "You" : (action.username ?? GENERIC_USERNAME)
        switch action.type {
        case .chat:
            return userString + " said: " + (action.message ?? GENERIC_CHAT)
        case .createEvent:
            return userString + " created \(eventName) at " + self.displayDate
        case .joinEvent:
            return userString + " joined \(eventName)"
        case .leaveEvent:
            return userString + " left \(eventName)"
        case .donation:
            return userString + " paid for \(eventName)"
        case .payForEvent:
            return userString + " paid for \(eventName)"
        default:
            // system message
            return "Admin says: hi"
        }
    }
    
    var userIsOrganizer: Bool {
        guard let owner = self.action.userId else { return false }
        guard let currentUserId = PlayerService.currentUser?.uid else { return false }
        
        return currentUserId == owner
    }
}
