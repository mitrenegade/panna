//
//  EventCellViewModel.swift
//  Panna
//
//  Created by Bobby Ren on 4/15/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import Foundation
import Balizinha

typealias EventStatus = (isPast: Bool, userIsOwner: Bool, userJoined: Bool)

class EventCellViewModel: NSObject {
    var event: Balizinha.Event

    init(event: Balizinha.Event) {
        self.event = event
        
        if let player = PlayerService.shared.current.value {
            containsUser = event.containsPlayer(player)
        } else {
            containsUser = false
        }
    }

    var containsUser: Bool = false

    var buttonTitle: String {
        guard !AuthService.isAnonymous else {
            return "Preview"
        }

        switch (event.isPast, event.userIsOrganizer, containsUser) {
        case (true, false, true):
            if SettingsService.donation() {
                return "Pay" // donate
            }
            else {
                return ""
            }
        case (true, false, false):
            return ""
        case (true, true, _):
            return ""
        case (false, true, _):
            return "Edit"
        case (false, false, let containsUser):
            return containsUser ? "Leave" : "Join"
        }
    }
    
    var buttonFont: UIFont {
        guard !AuthService.isAnonymous else {
            return UIFont.montserrat(size: 13)
        }
        return UIFont.montserrat(size: 16)
    }
    
    var buttonHidden: Bool {
        return event.isPast
    }
    
    var labelFullText: String? {
        if !event.isPast {
            // Button display and action
            
            if event.userIsOrganizer {
                return "This is your event."
            }
            else if containsUser {
                return "You're going!" //To-Do: Add functionality whether or not event is full
            }
            else {
                if event.isFull {
                    return "Event full"
                } else {
                    let left = event.maxPlayers - event.numPlayers
                    return "\(left) spots left"
                }
            }
        } else {
            return nil
        }
    }
    
    var buttonActionEnabled: Bool {
        if !event.isPast {
            // Button display and action
            
            if event.userIsOrganizer {
                return true
            }
            else if containsUser {
                return true
            }
            else {
                if event.isFull {
                    return false
                } else {
                    return true
                }
            }
        } else {
            return false
        }
    }
    
    var labelAttendanceText: String {
        return "\(event.numPlayers)"
    }
}
