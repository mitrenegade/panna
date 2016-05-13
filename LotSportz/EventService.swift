//
//  EventService.swift
//  LotSportz
//
//  Created by Bobby Ren on 5/12/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//
// EventService usage:
// var service = EventService.sharedInstance()
// service.getEvents()

import UIKit
import Firebase

private var eventServiceSingleton: EventService?
enum EventType: String {
    case Soccer
    case Basketball
    case FlagFootball = "Flag Football"
}

class EventService: NSObject {
    
    // MARK: - Singleton
    class func sharedInstance() -> EventService {
        if eventServiceSingleton == nil {
            eventServiceSingleton = EventService()
        }
        
        return eventServiceSingleton!
    }
    
    func getEvents(type type: String?) {
        // returns all current events of a certain type
        print("Get events")
        
    }
    
    func createEvent(eventDict eventDict: [NSObject: AnyObject]?) {
        print ("Create events")
        let eventRef = firebaseRef.childByAppendingPath("events") // this references the endpoint lotsports.firebase.com/events/
        let newEventRef: Firebase = eventRef.childByAutoId() // this generates an autoincremented event endpoint like lotsports.firebase.com/events/<uniqueId>
        
        if eventDict == nil {
            // TEST: Demo on how to use event. eventDict should not be nil in production
            newEventRef.setValue(["type": "soccer", "place": "Boston Commons, Boston MA", "time": NSDate().dateByAddingTimeInterval(3600*24*2).timeIntervalSince1970, "max_players": 20, "info": "This is a friendly pickup game"])
        }
        else {
            newEventRef.setValue(eventDict)
        }
    }
}
