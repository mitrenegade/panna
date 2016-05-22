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
    
    func createEvent(type: String = "soccer", place: String = "Boston Commons, Boston", time: NSDate = NSDate(), max_players: UInt = 1, info: String?) {
        print ("Create events")
        let eventRef = firRef.child("events") //firebaseRef.childByAppendingPath("events") // this references the endpoint lotsports.firebase.com/events/
        let newEventRef = eventRef.childByAutoId() // this generates an autoincremented event endpoint like lotsports.firebase.com/events/<uniqueId>
        
            // TEST: Demo on how to use event. eventDict should not be nil in production
        var params: [String: AnyObject] = ["type": type, "place": place, "time": time.dateByAddingTimeInterval(3600*24*2).timeIntervalSince1970, "max_players": max_players]
        if info == nil {
            params["info"] = info!
        }
        newEventRef.setValue(params)
        self.joinEvent(eventRef: newEventRef, join: true)
    }
    
    func joinEvent(eventRef eventRef: FIRDatabaseReference, join: Bool) {
        // use transactions: https://firebase.google.com/docs/database/ios/save-data#save_data_as_transactions
        // join: whether or not to join. Can use this method to leave an event
       
        eventRef.runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if currentData.value != nil, let uid = FIRAuth.auth()?.currentUser?.uid {
                var event = currentData.value as! [String : AnyObject]
                var participants : [String: Bool] // must be a dictionary
                participants = event["participants"] as? [String: Bool] ?? [:]
                if join {
                    // add self to participants
                    participants[uid] = true
                }
                else {
                    // remove self from participants
                    participants.removeValueForKey(uid)
                }
                event["participants"] = participants
                
                // Set value and report transaction success
                currentData.value = event
                
                print("Joing event Success: \(event)")
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        }) { (error, committed, snapshot) in
            if (error != nil) {
                print("Join event failure: \(error)")
                print(error?.localizedDescription)
            }
        }
    }
}
