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
    
    var league: String? {
        get {
            return self.dict["league"] as? String
        }
        set {
            self.dict["league"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
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
    
    var state: String? {
        get {
            return self.dict["state"] as? String
        }
        set {
            self.dict["state"] = newValue
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

    var lat: Double? {
        get {
            return self.dict["lat"] as? Double
        }
        set {
            self.dict["lat"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var lon: Double? {
        get {
            return self.dict["lon"] as? Double
        }
        set {
            self.dict["lon"] = newValue
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
    var maxPlayers: Int {
        get {
            if let val = self.dict["maxPlayers"] as? UInt {
                return Int(val)
            }
            else if let val = self.dict["max_players"] as? UInt { // backwards compatibility
                return Int(val)
            }
            return 0
        }
        set {
            self.dict["maxPlayers"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
        
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

    var paymentRequired: Bool {
        guard SettingsService.paymentRequired() else { return false }
        if let paymentRequired = self.dict["paymentRequired"] as? Bool {
            return paymentRequired
        }
        return false
    }
    
    var amount: NSNumber? {
        return self.dict["amount"] as? NSNumber
    }
    
    var owner: String? {
        return self.dict["owner"] as? String
    }
    
    var active: Bool {
        if let isActive = self.dict["active"] as? Bool {
            return isActive
        }
        
        return true
    }
}

// Utils
extension Event {
    func dateString(_ date: Date) -> String {
        //return "\((date as NSDate).day()) \(months[(date as NSDate).month() - 1]) \((date as NSDate).year())"
        return date.dateStringForPicker()
    }
    
    func timeString(_ date: Date) -> String {
        /*
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let time = formatter.string(from: date)
        return "\(time)"
        */
        return date.timeStringForPicker()
    }
    
    var numPlayers: Int {
        let users = self.users
        print("users: \(users.count)")
        return users.count
    }
    
    var users: [String] {
        guard let usersForEvents = self.service.usersForEvents else { return [] }
        if let results = usersForEvents[self.id] as? [String: AnyObject] {
            let filtered = results.filter({ (arg) -> Bool in
                
                let (key, val) = arg
                return val as! Bool
            })
            let userIds = filtered.map({ (arg) -> String in
                
                let (key, val) = arg
                return key
            })
            return userIds
        }
        return []
    }
    
    func containsUser(_ user: User) -> Bool {
        return self.users.contains(user.uid)
    }
    
    var isFull: Bool {
        return self.maxPlayers == self.numPlayers
    }
    
    var isPast: Bool {
        if let endTime = self.endTime {
            return (ComparisonResult.orderedAscending == endTime.compare(Date())) //event time happened before current time
        }
        else {
            return false // false means TBD
        }
    }
    
    var userIsOrganizer: Bool {
        guard let owner = self.owner else { return false }
        guard let user = AuthService.currentUser else { return false }
        
        return user.uid == owner
    }
    
    var locationString: String? {
        if let city = self.city, let state = self.state {
            return "\(city), \(state)"
        }
        else if let city = self.city {
            return city
        }
        else if let lat = lat, let lon = lon {
            return "\(lat), \(lon)"
        }
        return nil
    }
}

extension Event {
    //***************** hack: for test purposes only
    class func randomEvent() -> Event {
        let event = Event()
        let hours: Int = Int(arc4random_uniform(72))
        event.dict = ["type": event.randomType() as AnyObject, "place": event.randomPlace() as AnyObject, "startTime": (Date().timeIntervalSince1970 + Double(hours * 3600)) as AnyObject, "info": "Randomly generated event" as AnyObject]
        event.firebaseKey = FirebaseAPIService.uniqueId()
        return event
    }
    
    func randomType() -> String {
        let types: [EventType] = [.event3v3]
        let random = Int(arc4random_uniform(UInt32(types.count)))
        return types[random].rawValue
    }
    
    func randomPlace() -> String {
        let places = ["Boston", "New York", "Philadelphia", "Florida"]
        let random = Int(arc4random_uniform(UInt32(places.count)))
        return places[random]
    }
}
