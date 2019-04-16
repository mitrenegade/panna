//
//  EventCellViewModel.swift
//  Panna
//
//  Created by Bobby Ren on 4/15/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import Foundation
import Balizinha

typealias EventStatus = (isPast: Bool, userIsOwner: Bool, userJoined: Bool)

class EventCellViewModel: NSObject {
    func buttonTitle(eventStatus: EventStatus) -> String {
        guard !AuthService.isAnonymous else {
            return "Preview"
        }
        
        switch eventStatus {
        case (true, false, true):
            if SettingsService.donation() {
                return "Pay" // donate
            }
            else {
                return ""
            }
        case (true, false, false):
            return ""
        case (true, true, _):
            return ""
        case (false, true, _):
            return "Edit"
        case (false, false, let containsUser):
            return containsUser ? "Leave" : "Join"
        }
    }
    
    var buttonFont: UIFont {
        guard !AuthService.isAnonymous else {
            return UIFont.montserrat(size: 13)
        }
        return UIFont.montserrat(size: 16)
    }
}
