//
//  OrganizerCellViewModel.swift
//  Balizinha
//
//  Created by Bobby Ren on 1/21/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class OrganizerCellViewModel: NSObject {
    var labelTitle: String {
        if OrganizerService.shared.loading {
            return "Loading your organizer status"
        }
        
        guard let organizer = OrganizerService.shared.current else {
            return "Click to become an organizer"
        }

        switch organizer.status {
        case .pending:
            return "Your organizer status is pending approval"
        case .approved:
            return "You have been approved to be an organizer. Click to join"
        case .active:
            return "You are an organizer"
        case .none:
            return "Click to become an organizer"
        }
    }
    
    var canClick: Bool {
        if OrganizerService.shared.loading {
            return false
        }
        guard let organizer = OrganizerService.shared.current else {
            return true
        }
        switch organizer.status {
        case .pending, .active:
            return false
        case .approved, .none:
            return true
        }
    }
}
