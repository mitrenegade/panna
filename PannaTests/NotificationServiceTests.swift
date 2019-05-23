//
//  NotificationServiceTests.swift
//  PannaTests
//
//  Created by Bobby Ren on 5/22/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import XCTest
import Balizinha
@testable import Panna

class NotificationServiceTests: XCTestCase {
    let service = NotificationService()
    var event: Balizinha.Event!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        event = Balizinha.Event(key: "abc", dict: nil)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        event = nil
    }

    func testOneHourReminderString() {
        let interval: TimeInterval = 3600
        XCTAssertEqual(service.eventReminderString(event, interval: interval), "You have an event in an hour!")
    }

    func testTwoHourReminderString() {
        let interval: TimeInterval = 7200
        XCTAssertEqual(service.eventReminderString(event, interval: interval), "You have an event in two hours!")
    }
    
    func testSoonReminderString() {
        let interval: TimeInterval = 1800
        XCTAssertEqual(service.eventReminderString(event, interval: interval), "You have an event soon!")
    }
    
    func testEventNameReminderString() {
        event.name = "Test"
        let interval: TimeInterval = 3600
        XCTAssertEqual(service.eventReminderString(event, interval: interval), "Test starts in an hour!")
    }

    func testTimeStringHourReminderString() {
        let interval: TimeInterval = 4000
        event.startTime = Date()
        let string = service.eventReminderString(event, interval: interval)
        XCTAssertTrue(string.contains("You have an event at "), "Reminder string was \(string)")
    }
}
