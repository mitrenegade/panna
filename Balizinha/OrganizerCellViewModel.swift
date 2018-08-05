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
        
        guard let organizer = OrganizerService.shared.current.value else {
            return "Click to become an organizer"
        }

        switch organizer.status {
        case .pending:
            return "Organizer approval pending"
        case .approved:
            return "Organizer status approved"
        case .trial:
            return "You are a trial organizer"
        case .active:
            return "You are an organizer"
        case .none:
            return "Click to become an organizer"
        }
    }

    var labelDetail: String? {
        if OrganizerService.shared.loading {
            return nil
        }
        
        guard let organizer = OrganizerService.shared.current.value else {
            return "Submit a request here"
        }
        
        switch organizer.status {
        case .pending:
            return nil
        case .approved:
            return "Click to set up payment"
        case .active:
            return nil
        case .trial:
            return "The trial lasts a month"
        case .none:
            return "Submit a request here"
        }
    }
    
    var canClick: Bool {
        if OrganizerService.shared.loading {
            return false
        }
        guard let organizer = OrganizerService.shared.current.value else {
            return true
        }
        switch organizer.status {
        case .pending, .active, .trial:
            return false
        case .approved, .none:
            return true
        }
    }
}
