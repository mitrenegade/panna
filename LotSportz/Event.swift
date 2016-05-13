//
//  EventModel.swift
//  LotSportz
//
//  Created by Bobby Ren on 5/13/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

enum EventType: String {
    case Soccer
    case Basketball
    case FlagFootball = "Flag Football"
    case Other
}

class Event: FirebaseBaseModel {

    func type() -> String {
        if let val = self.dict["type"] as? String {
            return val
        }
        return EventType.Other.rawValue
    }
    
    func place() -> String {
        if let val = self.dict["place"] as? String {
            return val
        }
        return ""
    }

    func time() -> NSDate {
        if let val = self.dict["time"] as? NSTimeInterval {
            return NSDate(timeIntervalSince1970: val)
        }
        return NSDate() // what is a valid date equivalent of TBD?
    }
    
    func maxPlayers() -> Int {
        if let val = self.dict["max_players"] as? Int {
            return val
        }
        return 0
    }
    
    func info() -> String {
        if let val = self.dict["info"] as? String {
            return val
        }
        return ""
    }
}
