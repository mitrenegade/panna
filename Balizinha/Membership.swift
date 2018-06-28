//
//  Membership.swift
//  Balizinha
//
//  Created by Bobby Ren on 6/27/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

struct Membership {
    enum Status: String {
        case organizer
        case member
        case none
    }
    
    let playerId: String
    let status: Status
    
    init(id: String, status: String) {
        playerId = id
        self.status = Status(rawValue: status) ?? .none
    }
    
    var isActive: Bool { // returns if member OR organizer
        return status != .none
    }
    var isOrganizer: Bool {
        return status == .organizer
    }
}
