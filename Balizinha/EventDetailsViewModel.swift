//
//  EventDetailsViewModel.swift
//  Panna
//
//  Created by Bobby Ren on 4/3/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class EventDetailsViewModel: NSObject {
    let event: Balizinha.Event
    var userType: UserType? // used only to determine isAnonymous for guest users
    let defaults: DefaultsProvider
    init(event: Balizinha.Event, user: UserType? = AuthService.currentUser, defaults: DefaultsProvider = DefaultsManager.shared) {
        self.event = event
        userType = user
        self.defaults = defaults
    }
    
    var labelTitleText: String {
        let name = event.name ?? "Balizinha"
        let type = event.type.rawValue
        var title = "\(name)\n\(type)"
        if event.isCancelled {
            title = "\(name)\n🚫 (CANCELLED)\n\(type)"
        }
        return title
    }

    var spotsLeftLabelText: String {
        guard PlayerService.shared.current.value != nil else {
            return "\(event.numPlayers) are playing"
        }
        
        if event.isCancelled {
            return ""
        } else if event.isPast {
            return "\(event.numPlayers) joined this event"
        } else {
            if event.isFull {
                return "Event is full"
            } else {
                let spotsLeft = event.maxPlayers - event.numPlayers
                return "\(event.numPlayers) are playing (\(spotsLeft) available)"
            }
        }
    }
    
    // buttonClose
    var buttonCloseHidden: Bool {
        // handles anonymous user with a guest event
        guard let type = userType, type.isAnonymous, let eventId = defaults.value(forKey: DefaultsKey.guestEventId.rawValue) as? String, eventId == event.id else { return false }
        
        return true
    }
    
    var buttonCloseEnabled: Bool {
        return !buttonCloseHidden
    }
    
    // buttonClone
    var buttonCloneHidden: Bool {
        if event.userIsOrganizer() {
            return true
        }
        return false
    }
}
