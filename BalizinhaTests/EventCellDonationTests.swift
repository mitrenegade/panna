//
//  EventCellDonationTests.swift
//  Balizinha
//
//  Created by Bobby Ren on 10/9/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import XCTest

class EventCellDonationTests: XCTestCase {

    var cell: EventCell!
    var event: Event!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        cell = EventCell()
        event = Event()
        event.dict = ["name": "test"]
        cell.event = event
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
    }
    
    func testEventName() {
        XCAssert(true, "Event name appears correctly")
    }
    
    func testEventPast() {
        XCAssert(true, "Event should be past")
    }
}
