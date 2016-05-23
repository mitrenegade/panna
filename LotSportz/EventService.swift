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
import RandomKit

private var eventServiceSingleton: EventService?

private var TESTING = true

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
        
        if TESTING {
            let results = [Event.randomEvent(), Event.randomEvent(), Event.randomEvent(), Event.randomEvent(), Event.randomEvent(), Event.randomEvent()]
            completion(results: results)
            return
        }
        
        let eventQueryRef = firRef.child("events")//childByAppendingPath("events") // this creates a query on the endpoint lotsports.firebase.com/events/
        
        // sort by time
        eventQueryRef.queryOrderedByChild("time")
        
        // do query
        eventQueryRef.observeEventType(.Value) { (snapshot: FIRDataSnapshot!) in
            // this block is called for every result returned
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
    
    func createEvent(type: String = "soccer", place: String = "Boston Commons, Boston", time: NSDate = NSDate(), max_players: UInt = 1, info: String?) {
        print ("Create events")
        
        if TESTING {
            return
        }
        
        let eventRef = firRef.child("events") //firebaseRef.childByAppendingPath("events") // this references the endpoint lotsports.firebase.com/events/
        let newEventRef = eventRef.childByAutoId() // this generates an autoincremented event endpoint like lotsports.firebase.com/events/<uniqueId>
        
            // TEST: Demo on how to use event. eventDict should not be nil in production
        var params: [String: AnyObject] = ["type": type, "place": place, "time": time.dateByAddingTimeInterval(3600*24*2).timeIntervalSince1970, "max_players": max_players]
        if info == nil {
            params["info"] = info!
        }
        newEventRef.setValue(params)
  
        // TODO: automatically join event
//        self.joinEvent(event: Event(snapshot: newEventRef), join: true)
    }
    
    func joinEvent(event event: Event, join: Bool) {
        // use transactions: https://firebase.google.com/docs/database/ios/save-data#save_data_as_transactions
        // join: whether or not to join. Can use this method to leave an event
        let eventRef: FIRDatabaseReference = event.firRef!
        let participantRef = firRef.child("participants")
        let userId = firAuth?.currentUser?.uid
        let eventId = eventRef.key
        let newParticipantRef = participantRef.queryEqualToValue(userId, childKey: "user_id").queryEqualToValue(eventId, childKey: "event_id")
        newParticipantRef.observeEventType(.Value) { (snapshot: FIRDataSnapshot!) in
            print("results \(snapshot)")
        }
    }
}

extension Event {
    //***************** hack: for test purposes only
    class func randomEvent() -> Event {
        return Event()
    }
    
    convenience init() {
        self.init(snapshot: nil)
        self.firebaseKey = String.random()
        let hours: Int = Int(arc4random_uniform(72))
        self.dict = ["type": self.randomType(), "place": self.randomPlace(), "time": NSDate().dateByAddingHours(hours).timeIntervalSince1970, "info": "Randomly generated event"]
    }
    
    func randomType() -> String {
        let types: [EventType] = [.Soccer, .Basketball, .FlagFootball]
        let random = Int(arc4random_uniform(UInt32(types.count)))
        return types[random].rawValue
    }
    
    func randomPlace() -> String {
        let places = ["Boston", "New York", "Philadelphia", "Florida"]
        let random = Int(arc4random_uniform(UInt32(places.count)))
        return places[random]
    }
}
