//
//  CancelEventViewModel.swift
//  Panna
//
//  Created by Bobby Ren on 4/15/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import Foundation
import Balizinha

class CancelEventViewModel {
    let event: Balizinha.Event
    init(event: Balizinha.Event) {
        self.event = event
    }
    
    var cancelCellText: String {
        if event.isActive {
            return "Cancel Event"
        } else if event.isCancelled {
            return "Uncancel Event"
        } else {
            return ""
        }
    }
    
    var shouldShow: Bool { return !event.isPast }
    var alertTitle: String? = "Are you sure?"
    var alertMessage: String? = nil
    var alertConfirmButtonText: String? {
        if event.isActive {
            return "Yes, cancel this event"
        } else if event.isCancelled {
            return "Yes, uncancel this event"
        }
        return "Yes"
    }
}
