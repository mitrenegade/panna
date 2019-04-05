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

    var spotsLeftLabelText: String {
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
