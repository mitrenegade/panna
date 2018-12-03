//
//  GuestEventViewController.swift
//  Panna
//
//  Created by Bobby Ren on 12/2/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class GuestEventViewController: EventDisplayViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // handles anonymous user with a guest event
        guard AuthService.isAnonymous, let eventId = DefaultsManager.shared.value(forKey: DefaultsKey.guestEventId.rawValue) as? String, eventId == event?.id else { return }
        
        buttonClose.isHidden = true
        buttonClose.isEnabled = false
        
        func refreshJoin() {
            activityOverlay.hide()
            guard let event = event else { return }
            labelSpotsLeft.text = "\(event.numPlayers) are playing"

            buttonJoin.isEnabled = true
            buttonJoin.alpha = 1
            let spotsLeft = event.maxPlayers - event.numPlayers
            labelSpotsLeft.text = "\(spotsLeft) spots available"
        }
    }
}
