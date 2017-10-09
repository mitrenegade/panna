//
//  EventCellDonationTests.swift
//  Balizinha
//
//  Created by Bobby Ren on 10/9/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import XCTest

class EventCellDonationTests: XCTestCase {

    var viewModel: EventCellViewModel = EventCellViewModel()
    var event: Event?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        event = nil
    }
    
    func testEventName() {
        setupPastEvent()
//        XCTAssert(cell?.labelName.text == "PastEvent", "Event name appears correctly")
    }
    
    func testEventPast() {
        setupPastEvent()
        XCTAssert(event?.isPast == true, "Event should be past")
    }
    
    func testActionButtonForPastEvent() {
        setupPastEvent()
        guard let event = event else { return }
        XCTAssert(event.isPast == true, "Event should be past")
        let status = (event.isPast, false, false)
        XCTAssert(viewModel.buttonTitle(eventStatus: status) == "Donate", "Past events should show donate button")
    }
    
    fileprivate func setupPastEvent() {
        event = Event()
        let hours: Int = Int(arc4random_uniform(72))
        event?.dict = ["name": "PastEvent", "endTime": (Date().timeIntervalSince1970 - Double(hours * 3600)) as AnyObject, "info": "Randomly generated event" as AnyObject]
    }
}
