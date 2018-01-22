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
        if OrganizerService.shared.current == nil{
            return "Click to become an organizer"
        }
        return "You are an organizer"
    }
    
    var canClick: Bool {
        if OrganizerService.shared.loading {
            return false
        }
        if OrganizerService.shared.current == nil {
            return true
        }
        return false
    }
}
