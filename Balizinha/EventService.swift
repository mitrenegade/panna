//
//  EventService.swift
// Balizinha
//
//  Created by Bobby Ren on 5/12/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//
// EventService usage:
// var service = EventService.shared
// service.getEvents()

import UIKit
import Firebase

fileprivate var singleton: EventService?
var _usersForEvents: [String: AnyObject]?
var _events: [Event]?

class EventService: NSObject {
    private lazy var __once: () = {
            // firRef is the global firebase ref
            let queryRef = firRef.child("eventUsers") // this creates a query on the endpoint lotsports.firebase.com/events/
            queryRef.observe(.value) { (snapshot: DataSnapshot) in
                // this block is called for every result returned
                guard snapshot.exists() else { return }
                _usersForEvents = snapshot.value as? [String: AnyObject]
                
                NotificationCenter.default.post(name: NotificationType.EventsChanged.name(), object: nil)
            }
        }()
    
    // MARK: - Singleton
    static var shared: EventService {
        if singleton == nil {
            singleton = EventService()
        }
        
        return singleton!
    }
    
    class func resetOnLogout() {
        singleton = nil
    }

    var featuredEventId: String? {
        didSet {
            if let eventId = featuredEventId {
                withId(id: eventId, completion: {[weak self] (event) in
                    self?.featuredEvent = event
                    self?.notify(.EventsChanged, object: nil, userInfo: nil)
                })
            } else {
                featuredEvent = nil
            }
        }
    }
    
    var featuredEvent: Event?

    // MARK: - Global/constant listeners
    var usersForEvents: [String: AnyObject]? {
        return _usersForEvents
    }

    func listenForEventUsers() {
        _ = self.__once
    }
    
    // MARK: - Single call listeners
    
    func getEvents(type: String?, completion: @escaping (_ results: [Event]) -> Void) {
        // returns all current events of a certain type. Returns as snapshot
        // only gets events once, and removes observer afterwards
        print("Get events")
        
        if AIRPLANE_MODE {
            let results = [Event.randomEvent(), Event.randomEvent(), Event.randomEvent(), Event.randomEvent(), Event.randomEvent(), Event.randomEvent()]
            completion(results)
            return
        }
        
        let eventQueryRef = firRef.child("events")//childByAppendingPath("events") // this creates a query on the endpoint lotsports.firebase.com/events/
        
        // sort by time
        eventQueryRef.queryOrdered(byChild: "startTime")
        
        // filter for type - this does not work
        /*
        if let _ = type {
            // should be queryOrdered(byChild: "type").equalTo(type)
            eventQueryRef.queryEqual(toValue: type!, childKey: "type")
        }
        */
        
        // do query
        var handle: UInt = 0
        handle = eventQueryRef.observe(.value) { (snapshot: DataSnapshot) in
            // this block is called for every result returned
            guard snapshot.exists() else {
                return
            }
            var results: [Event] = []
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                for eventDict: DataSnapshot in allObjects {
                    let event = Event(snapshot: eventDict)
                    if event.active {
                        results.append(event)
                    }
                }
            }
            print("getEvents results count: \(results.count)")
            _events = results
            completion(results)
        }
    }
    
    func createEvent(_ name: String, type: EventType, city: String, state: String, lat: Double?, lon: Double?, place: String, startTime: Date, endTime: Date, maxPlayers: UInt, info: String?, paymentRequired: Bool, amount: NSNumber? = 0, completion:@escaping (Event?, NSError?) -> Void) {
        
        print ("Create events")
        
        if AIRPLANE_MODE {
            return
        }
        
        guard let user = AuthService.currentUser else { return }
        
        let eventRef = firRef.child("events") // this references the endpoint lotsports.firebase.com/events/
        let id = FirebaseAPIService.uniqueId()
        let newEventRef = eventRef.child(id) // this generates an autoincremented event endpoint like lotsports.firebase.com/events/<uniqueId>
        
        var params: [String: Any] = ["name": name, "type": type.rawValue, "city": city, "state": state, "place": place, "startTime": startTime.timeIntervalSince1970, "endTime": endTime.timeIntervalSince1970, "maxPlayers": maxPlayers, "owner": user.uid, "paymentRequired": paymentRequired]
        if let lat = lat, let lon = lon {
            params["lat"] = lat
            params["lon"] = lon
        }
        if paymentRequired {
            params["amount"] = amount
        }
        if info == nil {
            params["info"] = "No description available"
        } else {
            params["info"] = info as AnyObject?
        }
        
        newEventRef.setValue(params) { (error, ref) in
            if let error = error as? NSError {
                print(error)
                completion(nil, error)
            } else {
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    guard snapshot.exists() else {
                        completion(nil, nil)
                        return
                    }
                    guard let user = AuthService.currentUser else {
                        completion(nil, nil)
                        return
                    }
                    let event = Event(snapshot: snapshot)

                    // TODO: completion blocks for these too
                    self.addEvent(event: event, toUser: user, join: true)
                    self.addUser(user, toEvent: event, join: true)
                    
                    completion(event, nil)
                })
            }
        }
    }
    
    func deleteEvent(_ event: Event) {
        //let userId = user.uid
        let eventId = event.id
        let eventRef = firRef.child("events").child(eventId)
        eventRef.updateChildValues(["active": false])
        
        // remove users from that event by setting userEvent to false
        observeUsers(forEvent: event) { (ids) in
            for userId: String in ids {
                let userEventRef = firRef.child("userEvents").child(userId)
                let params: [String: Any] = [eventId: false]
                userEventRef.updateChildValues(params, withCompletionBlock: { (error, ref) in
                })
            }
        }

    
    }
    func joinEvent(_ event: Event) {
        guard let user = AuthService.currentUser else { return }
        self.addEvent(event: event, toUser: user, join: true)
        self.addUser(user, toEvent: event, join: true)
    }
    
    func leaveEvent(_ event: Event) {
        guard let user = AuthService.currentUser else { return }
        self.addEvent(event: event, toUser: user, join: false)
        self.addUser(user, toEvent: event, join: false)
    }
    
    // MARK: User's events helper
    func addEvent(event: Event, toUser user: User, join: Bool) {
        // adds eventId to user's events list
        // use transactions: https://firebase.google.com/docs/database/ios/save-data#save_data_as_transactions
        // join: whether or not to join. Can use this method to leave an event

        let userId = user.uid
        let eventId = event.id
        let userEventRef = firRef.child("userEvents").child(userId)
        let params: [String: Any] = [eventId: join]
        userEventRef.updateChildValues(params, withCompletionBlock: { (error, ref) in
            print("ref \(ref)")
        })
        /*
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
        */
    }
    
    func getEventsForUser(_ user: User, completion: @escaping (_ eventIds: [String]) -> Void) {
        // returns all current events for a user. Returns as snapshot
        // only gets events once, and removes observer afterwards
        print("Get events for user \(user.uid)")
        
        let eventQueryRef = firRef.child("userEvents").child(user.uid) // this creates a query on the endpoint lotsports.firebase.com/events/
        
        // do query
        var handle: UInt = 0
        handle = eventQueryRef.observe(.value) { (snapshot: DataSnapshot) in
            guard snapshot.exists() else {
                completion([])
                return
            }
            // this block is called for every result returned
            var results: [String] = []
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                for snapshot: DataSnapshot in allObjects {
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
            //eventQueryRef.removeObserver(withHandle: handle)
        }
    }
    
    // MARK: - Event's users helper
    func addUser(_ user: User, toEvent event: Event, join: Bool) {
        // adds eventId to user's events list
        // use transactions: https://firebase.google.com/docs/database/ios/save-data#save_data_as_transactions
        // join: whether or not to join. Can use this method to leave an event
        
        let userId = user.uid
        let eventId = event.id
        let eventUserRef = firRef.child("eventUsers").child(eventId)
        let params: [String: Any] = [userId: join]
        eventUserRef.updateChildValues(params, withCompletionBlock: { (error, ref) in
            print("ref \(ref)")
        })
        /*
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
        */
    }
    
    func observeUsers(forEvent event: Event, completion: @escaping (_ userIds: [String]) -> Void) {
        // TODO: return each event instead of a list of userIds
        
        if AIRPLANE_MODE {
            completion([])
            return 
        }
        
        // returns all current events for a user. Returns as snapshot
        // only gets events once, and removes observer afterwards
        print("Get users for event \(event.id)")
        
        let queryRef = firRef.child("eventUsers").child(event.id) // this creates a query on the endpoint lotsports.firebase.com/events/
        
        // do query
        queryRef.observe(.value) { (snapshot: DataSnapshot) in
            guard snapshot.exists() else { return }
            // this block is called for every result returned
            var results: [String] = []
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                for snapshot: DataSnapshot in allObjects {
                    let userId = snapshot.key
                    if let val = snapshot.value as? Bool, val == true {
                        results.append(userId)
                    }
                }
            }
            print("getUsersForEvent \(event.id) results count: \(results.count)")
            completion(results)
        }
    }
    
    func totalAmountPaid(for event: Event, completion: ((Double, Int)->())?) {
        let queryRef = firRef.child("charges/events").child(event.id)
        queryRef.observe(.value) { (snapshot: DataSnapshot) in
            guard snapshot.exists() else {
                completion?(0, 0)
                return
            }
            var total: Double = 0
            var count: Int = 0
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                for snapshot: DataSnapshot in allObjects {
                    let playerId = snapshot.key // TODO: display all players who've paid
                    let payment = Payment(snapshot: snapshot)
                    guard payment.paid, let amount = payment.amount, let refunded = payment.refunded else { continue }
                    let netPayment: Double = (amount.doubleValue - refunded.doubleValue) / 100.0
                    total += netPayment
                    count += 1
                    print("Charges \(event.id): payment by \(playerId) = \(netPayment)")
                }
            }
            completion?(total, count)
        }
    }
}

// MARK: - Payment helpers
extension EventService {
    class func amountNumber(from text: String?) -> NSNumber? {
        guard let inputText = text else { return nil }
        if let amount = Double(inputText) {
            return amount as NSNumber
        }
        else if let amount = currencyFormatter.number(from: inputText) {
            return amount
        }
        return nil
    }
    
    class func amountString(from number: NSNumber?) -> String? {
        guard let number = number else { return nil }
        return currencyFormatter.string(from: number)
    }
    
    fileprivate static var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.currencyDecimalSeparator = "."
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        return formatter
    }
}

extension EventService {
    func withId(id: String, completion: @escaping ((Event?)->Void)) {
        if let foundEvent = _events?.first(where: { (event) -> Bool in
            return event.id == id
        }) {
            completion(foundEvent)
            return
        }
        
        let eventRef = firRef.child("events")
        eventRef.child(id).observeSingleEvent(of: .value, with: { (snapshot) in
            guard snapshot.exists() else {
                completion(nil)
                return
            }
            let event = Event(snapshot: snapshot)
            completion(event)
        })
    }
}
