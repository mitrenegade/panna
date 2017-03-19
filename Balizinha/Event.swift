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
    case event3v3 = "3 vs 3"
    case event5v5 = "5 vs 5"
    case event7v7 = "7 vs 7"
    case event11v11 = "11 vs 11"
    case other
}

fileprivate let formatter = DateFormatter()

class Event: FirebaseBaseModel {
    var service = EventService.shared
    
    var name: String? {
        get {
            return self.dict["name"] as? String
        }
        set {
            self.dict["name"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

    var type: EventType {
        get {
            for type: EventType in [.event3v3, .event5v5, .event7v7, .event11v11] {
                if type.rawValue == self.dict["type"] as? String {
                    return type
                }
            }
            return .other
        }
        set {
            self.dict["type"] = newValue.rawValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var photoUrl: String? {
        get {
            return self.dict["photoUrl"] as? String
        }
        set {
            self.dict["photoUrl"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var city: String? {
        get {
            return self.dict["city"] as? String
        }
        set {
            self.dict["city"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var place: String? {
        get {
            return self.dict["place"] as? String
        }
        set {
            self.dict["place"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var startTime: Date? {
        get {
            if let val = self.dict["startTime"] as? TimeInterval {
                return Date(timeIntervalSince1970: val)
            }
            return nil // what is a valid date equivalent of TBD?
        }
        set {
            self.dict["startTime"] = newValue?.timeIntervalSince1970
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var endTime: Date? {
        get {
            if let val = self.dict["endTime"] as? TimeInterval {
                return Date(timeIntervalSince1970: val)
            }
            return nil // what is a valid date equivalent of TBD?
        }
        set {
            self.dict["endTime"] = newValue?.timeIntervalSince1970
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
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
        get {
            if let val = self.dict["max_players"] as? Int {
                return val
            }
            return 0
        }
        set {
            self.dict["max_players"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
        
    }
    
    var numPlayers: Int {
        let users = self.users
        print("users: \(users.count)")
        return users.count
    }
    
    var info: String {
        get {
            if let val = self.dict["info"] as? String {
                return val
            }
            return ""
        }
        set {
            self.dict["info"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
        
    }
    
    var users: [String] {
        guard let usersForEvents = self.service.usersForEvents else { return [] }
        if let results = usersForEvents[self.id] as? [String: AnyObject] {
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
        if let startTime = self.startTime {
            return (ComparisonResult.orderedAscending == startTime.compare(Date())) //event time happened before current time
        }
        else {
            return false // false means TBD
        }
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
