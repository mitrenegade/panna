//
//  Organizer.swift
//  Balizinha
//
//  Created by Bobby Ren on 10/2/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

enum OrganizerStatus: String, Equatable {
    case none // default, but players who are not organizers won't have an organizer object
    case pending
    case approved // needs payment
    case active
}

func ==(lhs: OrganizerStatus, rhs: OrganizerStatus) -> Bool {
    switch (lhs, rhs) {
    case (.none, .none):
        return true
    case (.pending, .pending):
        return true
    case (.approved, .approved):
        return true
    case (.active, .active):
        return true

    default:
        return false
    }
}


class Organizer: FirebaseBaseModel {
    static let nilOrganizer: Organizer = Organizer() // if organizer is nil but needs to be an event in an observable

    var paymentSourceId: String? {
        guard let dict = self.dict else { return nil }
        return dict["paymentSourceId"] as? String
    }
    
    var paymentNeeded: Bool {
        get {
            return self.dict?["paymentNeeded"] as? Bool ?? false
        }
        set {
            self.dict["paymentNeeded"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

    var deadline: Double? {
        get {
            return self.dict?["deadline"] as? Double
        }
        set {
            self.dict["deadline"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var status: OrganizerStatus {
        if let statusString = self.dict?["status"] as? String, let organizerStatus = OrganizerStatus(rawValue: statusString) {
            return organizerStatus
        }
        return .none
    }
}
