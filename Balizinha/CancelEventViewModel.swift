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
    init(event: Balizinha.Event) {
        if event.isActive {
            cancelCellText = "Cancel Event"
        } else if event.isCancelled {
            cancelCellText = "Uncancel Event"
        } else {
            cancelCellText = ""
        }
        
        shouldShow = !event.isPast
        alertTitle = "Are you sure?"
        alertMessage = nil
        if event.isActive {
            alertConfirmButtonText = "Yes, cancel this event"
        } else if event.isCancelled {
            alertConfirmButtonText = "Yes, uncancel this event"
        }
    }
    
    // Cell
    let shouldShow: Bool!
    let cancelCellText: String!
    
    // alert
    var alertTitle: String?
    var alertMessage: String?
    var alertConfirmButtonText: String?
}
