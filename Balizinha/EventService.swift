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
private var TESTING = false
var _usersForEvents: [String: AnyObject]?

class EventService: NSObject {
    
    private lazy var __once: () = {
            // firRef is the global firebase ref
            let queryRef = firRef.child("eventUsers") // this creates a query on the endpoint lotsports.firebase.com/events/
            queryRef.observe(.value) { (snapshot: FIRDataSnapshot!) in
                // this block is called for every result returned
                _usersForEvents = snapshot.value as? [String: AnyObject]
            }
        }()
    
    // MARK: - Singleton
    class func sharedInstance() -> EventService {
        if eventServiceSingleton == nil {
            eventServiceSingleton = EventService()
        }
        
        return eventServiceSingleton!
    }
    
    // MARK: - Global/constant listeners
    var usersForEvents: [String: AnyObject]? {
        return _usersForEvents
    }
    func listenForEventUsers() {
        var onceToken: Int = 0
        _ = self.__once
    }
    
    // MARK: - Single call listeners
    
    func getEvents(type: String?, completion: @escaping (_ results: [Event]) -> Void) {
        // returns all current events of a certain type. Returns as snapshot
        // only gets events once, and removes observer afterwards
        print("Get events")
        
        if TESTING {
            let results = [Event.randomEvent(), Event.randomEvent(), Event.randomEvent(), Event.randomEvent(), Event.randomEvent(), Event.randomEvent()]
            completion(results)
            return
        }
        
        let eventQueryRef = firRef.child("events")//childByAppendingPath("events") // this creates a query on the endpoint lotsports.firebase.com/events/
        
        // sort by time
        eventQueryRef.queryOrdered(byChild: "startTime")
        
        // filter for type
        if let _ = type {
            eventQueryRef.queryEqual(toValue: type!, childKey: "type")
        }
        
        // do query
        var handle: UInt = 0
        handle = eventQueryRef.observe(.value) { (snapshot: FIRDataSnapshot!) in
            // this block is called for every result returned
            var results: [Event] = []
            if let allObjects =  snapshot.children.allObjects as? [FIRDataSnapshot] {
                for eventDict: FIRDataSnapshot in allObjects {
                    let event = Event(snapshot: eventDict)
                    results.append(event)
                }
            }
            print("getEvents results count: \(results.count)")
            completion(results)
            eventQueryRef.removeObserver(withHandle: handle)
        }
    }
    
    func createEvent(_ type: String, city: String, place: String, startTime: Date, endTime: Date, max_players: UInt, info: String?, completion:@escaping (Event?, NSError?) -> Void) {
        
        print ("Create events")
        
        if TESTING {
            return
        }
        
        let eventRef = firRef.child("events") // this references the endpoint lotsports.firebase.com/events/
        let newEventRef = eventRef.childByAutoId() // this generates an autoincremented event endpoint like lotsports.firebase.com/events/<uniqueId>
        
        var params: [String: AnyObject] = ["type": type as AnyObject, "city": city as AnyObject, "place": place as AnyObject, "startTime": startTime.timeIntervalSince1970 as AnyObject, "endTime": endTime.timeIntervalSince1970 as AnyObject, "max_players": max_players as AnyObject]
        if info == nil {
            params["info"] = "No description available" as AnyObject?
        } else {
            params["info"] = info as AnyObject?
        }
        
        newEventRef.setValue(params) { (error, ref) in
            if error != nil {
                print(error)
                completion(nil, error as NSError?)
            } else {
                ref.observe(.value, with: { (snapshot) in
                    let event = Event(snapshot: snapshot)
                    // TODO: completion blocks for these too
                    self.addEvent(event: event, toUser: firAuth!.currentUser!, join: true)
                    self.addUser(firAuth!.currentUser!, toEvent: event, join: true)
                    completion(event, nil)
                })
            }
        }
    }
    
    func joinEvent(_ event: Event, user: FIRUser) {
        self.addEvent(event: event, toUser: user, join: true)
        self.addUser(user, toEvent: event, join: true)
    }
    
    func leaveEvent(_ event: Event, user: FIRUser) {
        self.addEvent(event: event, toUser: user, join: false)
        self.addUser(user, toEvent: event, join: false)
    }
    
    // MARK: User's events helper
    func addEvent(event: Event, toUser user: FIRUser, join: Bool) {
        // adds eventId to user's events list
        // use transactions: https://firebase.google.com/docs/database/ios/save-data#save_data_as_transactions
        // join: whether or not to join. Can use this method to leave an event

        let usersRef = firRef.child("userEvents")
        let userId = user.uid
        let eventId = event.id
        usersRef.runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            var allUserEvents: [String: AnyObject] = [:]
            if currentData.hasChildren() {
                print("has children: \(currentData.hasChildren()))")
                allUserEvents = currentData.value as! [String : AnyObject] // results of /userEvents
            }
            // create or get events for given user
            var userEvents : [String: Bool] = allUserEvents[userId] as? [String: Bool] ?? [:]
            if join {
                // add event to list of events for user
                userEvents[eventId] = true
            }
            else {
                // remove event from events for user
                userEvents.removeValue(forKey: eventId)
            }
            allUserEvents[userId] = userEvents as AnyObject?
            
            // Set value and report transaction success
            currentData.value = allUserEvents
            
            return FIRTransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if (error != nil) {
                print("Join event failure: \(error)")
                print(error?.localizedDescription)
            }
        }
    }
    
    func getEventsForUser(_ user: FIRUser, completion: @escaping (_ eventIds: [String]) -> Void) {
        // returns all current events for a user. Returns as snapshot
        // only gets events once, and removes observer afterwards
        print("Get events for user \(user.uid)")
        
        let eventQueryRef = firRef.child("userEvents").child(user.uid) // this creates a query on the endpoint lotsports.firebase.com/events/
        
        // do query
        var handle: UInt = 0
        handle = eventQueryRef.observe(.value) { (snapshot: FIRDataSnapshot!) in
            // this block is called for every result returned
            var results: [String] = []
            if let allObjects =  snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snapshot: FIRDataSnapshot in allObjects {
                    let eventId = snapshot.key
                    if let val = snapshot.value as? Bool {
                        if val == true {
                            results.append(eventId)
                        }
                    }
                }
            }
            print("getEventsForUser \(user.uid) results count: \(results.count)")
            completion(results)
            eventQueryRef.removeObserver(withHandle: handle)
        }
    }
    
    // MARK: - Event's users helper
    func addUser(_ user: FIRUser, toEvent event: Event, join: Bool) {
        // adds eventId to user's events list
        // use transactions: https://firebase.google.com/docs/database/ios/save-data#save_data_as_transactions
        // join: whether or not to join. Can use this method to leave an event
        
        let eventsRef = firRef.child("eventUsers")
        let userId = user.uid
        let eventId = event.id
        eventsRef.runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            var allEventUsers: [String: AnyObject] = [:]
            if currentData.hasChildren() {
                print("has children: \(currentData.hasChildren()))")
                allEventUsers = currentData.value as! [String : AnyObject] // results of /userEvents
            }
            // create or get users for given event
            var eventUsers : [String: Bool] = allEventUsers[eventId] as? [String: Bool] ?? [:]
            if join {
                // add user to users for event
                eventUsers[userId] = true
            }
            else {
                // remove user from list of users
                eventUsers.removeValue(forKey: userId)
            }
            allEventUsers[eventId] = eventUsers as AnyObject?
            
            // Set value and report transaction success
            currentData.value = allEventUsers
            
            return FIRTransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if (error != nil) {
                print("Join event failure: \(error)")
                print(error?.localizedDescription)
            }
        }
    }
    
    func getUsersForEvent(_ event: Event, completion: @escaping (_ userIds: [String]) -> Void) {
        // returns all current events for a user. Returns as snapshot
        // only gets events once, and removes observer afterwards
        print("Get users for event \(event.id)")
        
        let queryRef = firRef.child("eventUsers").child(event.id) // this creates a query on the endpoint lotsports.firebase.com/events/
        
        // do query
        var handle: UInt = 0
        handle = queryRef.observe(.value) { (snapshot: FIRDataSnapshot!) in
            // this block is called for every result returned
            var results: [String] = []
            if let allObjects =  snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snapshot: FIRDataSnapshot in allObjects {
                    let userId = snapshot.key
                    if let val = snapshot.value as? Bool {
                        if val == true {
                            results.append(userId)
                        }
                    }
                }
            }
            print("getUsersForEvent \(event.id) results count: \(results.count)")
            completion(results)
            queryRef.removeObserver(withHandle: handle)
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
        self.dict = ["type": self.randomType() as AnyObject, "place": self.randomPlace() as AnyObject, "time": (Date() as NSDate).addingHours(hours).timeIntervalSince1970 as AnyObject, "info": "Randomly generated event" as AnyObject]
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


