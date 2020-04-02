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
    var player: Player?
    var userType: UserType? // used only to determine isAnonymous for guest users
    let defaults: DefaultsProvider
    init(event: Balizinha.Event, user: UserType? = AuthService.currentUser, defaults: DefaultsProvider = DefaultsManager.shared, player: Player?) {
        self.event = event
        userType = user
        self.defaults = defaults
        self.player = player
    }
    
    var labelTitleText: String {
        let name = event.name ?? "Balizinha"
        let type = event.typeString
        var title = "\(name)\n\(type)"
        if event.isCancelled {
            title = "\(name)\n🚫 (CANCELLED)\n\(type)"
        }
        return title
    }

    var spotsLeftLabelText: String {
        guard PlayerService.shared.current.value != nil else {
            return "\(event.numPlayers()) are playing"
        }
        
        if event.isCancelled {
            return ""
        } else if event.isPast {
            return "\(event.numPlayers()) joined this event"
        } else {
            if event.isFull {
                return "Event is full"
            } else {
                let spotsLeft = event.maxPlayers - event.numPlayers()
                return "\(event.numPlayers()) are playing (\(spotsLeft) available)"
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
    
    var buttonOptOutTitle: String {
        guard let player = PlayerService.shared.current.value, event.playerHasResponded(player) else {
            return "Opt out of this game"
        }
        return event.playerIsAttending(player) ? "" : "You are not attending"
    }

    var buttonOptOutEnabled: Bool {
        guard let player = PlayerService.shared.current.value, event.playerHasResponded(player) else {
            return true
        }
        return false
    }
    
    // MARK: - Videolink
    var videoLinkHidden: Bool {
        return event.validVideoUrl == nil || !SettingsService.useVideoLink
    }
    
    var isVideoLinkButtonEnabled: Bool {
        guard let player = player else { return false }
        return event.playerIsAttending(player)
    }
    
    var videoLinkLabel: String {
        guard isVideoLinkButtonEnabled else { return "Join to see video link" }
        if let urlString = event.validVideoUrl?.absoluteString {
            return "Join via video: \(urlString)"
        }
        return ""
    }
}
