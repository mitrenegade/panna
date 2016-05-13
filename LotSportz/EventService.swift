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
    
    func getEvents(type: String?) {
        // returns all current events of a certain type
        print("Get events")
    }
    
    func createEvent() {
        print ("Create events")
    }
}
