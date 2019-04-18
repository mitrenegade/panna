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
    init(event: Balizinha.Event) {
        self.event = event
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
        
        if event.isPast {
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
}
