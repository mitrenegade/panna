//
//  EventModel.swift
//  LotSportz
//
//  Created by Bobby Ren on 5/13/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

enum EventType: String {
    case Soccer = "Soccer"
    case Basketball = "Basketball"
    case FlagFootball = "Flag Football"
    case Other
}

var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
let formatter = NSDateFormatter()

class Event: FirebaseBaseModel {
    var service = EventService.sharedInstance()
    
    func type() -> String {
        if let val = self.dict["type"] as? String {
            return val
        }
        return EventType.Other.rawValue
    }
    
    func city() -> String {
        if let val = self.dict["city"] as? String {
            return val
        }
        return ""
    }
    
    func place() -> String {
        if let val = self.dict["place"] as? String {
            return val
        }
        return ""
    }
    
    /* Old model
    func time() -> NSDate {
        if let val = self.dict["time"] as? NSTimeInterval {
            return NSDate(timeIntervalSince1970: val)
        }
        return NSDate() // what is a valid date equivalent of TBD?
    } //To-Do: Add begin/end time
    */
    
    func startTime() -> NSDate {
        if let val = self.dict["startTime"] as? NSTimeInterval {
            return NSDate(timeIntervalSince1970: val)
        }
        return NSDate() // what is a valid date equivalent of TBD?
    } //To-Do: Add begin/end time

    
    func endTime() -> NSDate {
        if let val = self.dict["endTime"] as? NSTimeInterval {
            return NSDate(timeIntervalSince1970: val)
        }
        return NSDate() // what is a valid date equivalent of TBD?
    } //To-Do: Add begin/end time

    
    func dateString(date: NSDate) -> String {
        return "\(date.day()) \(months[date.month() - 1]) \(date.year())"
    }

    func timeString(date: NSDate) -> String {
        formatter.dateStyle = .NoStyle
        formatter.timeStyle = .ShortStyle
        let time = formatter.stringFromDate(date)
        return "\(time)"
        
    }
    
    func maxPlayers() -> Int {
        if let val = self.dict["max_players"] as? Int {
            return val
        }
        return 0
    }
    
    func numPlayers() -> Int {
        let users = self.users()
        print("users: \(users.count)")
        return users.count
    }
    
    func info() -> String {
        if let val = self.dict["info"] as? String {
            return val
        }
        return ""
    }
    
    func users() -> [String] {
        print("usersForEvents: \(self.service.usersForEvents!)")
        if let results = self.service.usersForEvents![self.id()] as? [String: AnyObject] {
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
    
    func containsUser(user: FIRUser) -> Bool {
        return self.users().contains(user.uid)
    }
    
    func isFull() -> Bool {
        return self.maxPlayers() == self.numPlayers()
    }
    
    func isPast() -> Bool {
        return (NSComparisonResult.OrderedAscending == self.startTime().compare(NSDate())) //event time happened before current time
    }
}
