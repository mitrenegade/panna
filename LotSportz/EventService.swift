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

class EventService: NSObject {
    
    // MARK: - Singleton
    class func sharedInstance() -> EventService {
        if eventServiceSingleton == nil {
            eventServiceSingleton = EventService()
        }
        
        return eventServiceSingleton!
    }
    
    func listenForEvents(type type: String?, completion: (results: [Event]) -> Void) {
        // returns all current events of a certain type. Returns as snapshot
        print("Get events")
        
        let eventQueryRef = firRef.child("events")//childByAppendingPath("events") // this creates a query on the endpoint lotsports.firebase.com/events/
        
        // sort by time
        eventQueryRef.queryOrderedByChild("time")
        
        // do query
        eventQueryRef.observeEventType(.Value) { (snapshot: FIRDataSnapshot!) in
            // this block is called for every result returnedd
            var results: [Event] = []
            if let allObjects =  snapshot.children.allObjects as? [FIRDataSnapshot] {
                for eventDict: FIRDataSnapshot in allObjects {
                    let event = Event(snapshot: eventDict)
                    results.append(event)
                }
            }
            completion(results: results)
        }
    }
    
    func createEvent(eventDict eventDict: [NSObject: AnyObject]?) {
        print ("Create events")
        let eventRef = firRef.child("events") //firebaseRef.childByAppendingPath("events") // this references the endpoint lotsports.firebase.com/events/
        let newEventRef = eventRef.childByAutoId() // this generates an autoincremented event endpoint like lotsports.firebase.com/events/<uniqueId>
        
        if eventDict == nil {
            // TEST: Demo on how to use event. eventDict should not be nil in production
            newEventRef.setValue(["type": "soccer", "place": "Boston Commons, Boston MA", "time": NSDate().dateByAddingTimeInterval(3600*24*2).timeIntervalSince1970, "max_players": 20, "info": "This is a friendly pickup game"])
        }
        else {
            newEventRef.setValue(eventDict)
        }
    }
}
