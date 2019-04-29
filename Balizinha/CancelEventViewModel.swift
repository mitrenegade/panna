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
            return "Cancel/Delete Event"
        } else if event.isCancelled {
            return "Uncancel/Delete Event"
        } else {
            return ""
        }
    }
    
    var cancelOptionText: String {
        if event.isActive {
            return "Cancel Event"
        } else {
            return "Uncancel Event"
        }
    }
    
    var deleteOptionText: String {
        return "Delete Event"
    }
    
    var shouldShow: Bool { return !event.isPast }
    var alertTitle: String? {
        if event.isCancelled {
            return "This event is inactive"
        } else {
            return "This event is active"
        }
    }

    var cancelMessage: String? {
        if event.isCancelled {
            return "Are you sure you want to uncancel it? It will become available to join."
        } else {
            return "Are you sure you want to cancel this event? It will no longer be available."
        }
    }

    var cancelConfirmButtonText: String? {
        if event.isActive {
            return "Yes, cancel this event"
        } else if event.isCancelled {
            return "Yes, uncancel this event"
        }
        return "Yes"
    }
    
    var deleteMessage: String? {
        return "Are you sure you want to delete this event? This cannot be undone."
    }
    
    var deleteConfirmButtonText: String? {
        return "Confirm delete"
    }
    
    var alertCancelText: String {
        return "Not now"
    }
}
