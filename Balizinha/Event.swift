//
//  EventModel.swift
// Balizinha
//
//  Created by Bobby Ren on 5/13/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

enum EventType: String {
    case basketball = "Basketball"
    case flagFootball = "Flag Football"
    
    // balizinha only
    case event3v3 = "3 vs 3"
    case event5v5 = "5 vs 5"
    case balizinha = "Balizinha"

    case other
}

fileprivate let formatter = DateFormatter()

class Event: FirebaseBaseModel {
    var service = EventService.shared
    
    var type: EventType {
        for type: EventType in [.event3v3, .event5v5, .balizinha] {
            if type.rawValue == self.dict["type"] as? String {
                return type
            }
        }
        return .other
    }
    
    var city: String? {
        if let val = self.dict["city"] as? String {
            return val
        }
        return nil
    }
    
    var place: String? {
        if let val = self.dict["place"] as? String {
            return val
        }
        return nil
    }
    
    /* Old model
    var time: NSDate {
        if let val = self.dict["time"] as? NSTimeInterval {
            return NSDate(timeIntervalSince1970: val)
        }
        return NSDate() // what is a valid date equivalent of TBD?
    } //To-Do: Add begin/end time
    */
    
    var startTime: Date {
        if let val = self.dict["startTime"] as? TimeInterval {
            return Date(timeIntervalSince1970: val)
        }
        return Date() // what is a valid date equivalent of TBD?
    } //To-Do: Add begin/end time

    
    var endTime: Date {
        if let val = self.dict["endTime"] as? TimeInterval {
            return Date(timeIntervalSince1970: val)
        }
        return Date() // what is a valid date equivalent of TBD?
    } //To-Do: Add begin/end time

    
    func dateString(_ date: Date) -> String {
        return "\((date as NSDate).day()) \(months[(date as NSDate).month() - 1]) \((date as NSDate).year())"
    }

    func timeString(_ date: Date) -> String {
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let time = formatter.string(from: date)
        return "\(time)"
        
    }
    
    var maxPlayers: Int {
        if let val = self.dict["max_players"] as? Int {
            return val
        }
        return 0
    }
    
    var numPlayers: Int {
        let users = self.users
        print("users: \(users.count)")
        return users.count
    }
    
    var info: String {
        if let val = self.dict["info"] as? String {
            return val
        }
        return ""
    }
    
    var users: [String] {
        print("usersForEvents: \(self.service.usersForEvents!)")
        if let results = self.service.usersForEvents![self.id] as? [String: AnyObject] {
            let filtered = results.filter({ (key, val) -> Bool in
                return val as! Bool
            })
            let userIds = filtered.map({ (key, val) -> String in
                return key
            })
            return userIds
        }
        return []
    }
    
    func containsUser(_ user: FIRUser) -> Bool {
        return self.users.contains(user.uid)
    }
    
    var isFull: Bool {
        return self.maxPlayers == self.numPlayers
    }
    
    var isPast: Bool {
        return (ComparisonResult.orderedAscending == self.startTime.compare(Date())) //event time happened before current time
    }
    
    var owner: String? {
        return self.dict["owner"] as? String
    }
    
    var userIsOwner: Bool {
        guard let owner = self.owner else { return false }
        guard let user = firAuth?.currentUser else { return false }

        return user.uid == owner
    }
    
    var locationString: String? {
        if let city = self.city, let place = self.place {
            return "\(place), \(city)"
        }
        else if let city = self.city {
            return city
        }
        else if let place = self.place {
            return place
        }
        return nil
    }
}
