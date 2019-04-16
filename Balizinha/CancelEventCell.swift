//
//  CancelEventCell.swift
//  Panna
//
//  Created by Bobby Ren on 4/11/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import UIKit
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

class CancelEventCell: UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
    var viewModel: CancelEventViewModel?

    func configure(_ event: Balizinha.Event) {
        viewModel = CancelEventViewModel(event: event)
        label.text = viewModel?.cancelCellText
    }
}
