//
//  RecurrenceToggleCellTests.swift
//  PannaTests
//
//  Created by Bobby Ren on 9/12/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import XCTest

class RecurrenceToggleCellTests: XCTestCase {
    let cell = RecurrenceToggleCell()
    let viewModel = RecurrenceToggleCellViewModel()
    
    func testSelectRecurrence() {
        //cell.selectRecurrence(.none)
    }
    
    func testGeneratePickerDatesForNone() {
        let recurrence: Date.Recurrence = .none
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(1)
        let dates = viewModel.datesForRecurrence(recurrence, startDate: startDate, endDate: endDate)
        XCTAssertTrue(dates.count == 1)
        XCTAssertTrue(dates[0] == startDate)
    }
    
    func testGeneratePickerDatesForDailyWithEarlyEndDate() {
        let recurrence: Date.Recurrence = .daily
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(1)
        let dates = viewModel.datesForRecurrence(recurrence, startDate: startDate, endDate: endDate)
        XCTAssertTrue(dates.count == 1)
        XCTAssertTrue(dates[0] == startDate)
    }

    func testGeneratePickerDatesForDailyWithSingleDayEndDate() {
        let recurrence: Date.Recurrence = .daily
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(24*3600)
        let dates = viewModel.datesForRecurrence(recurrence, startDate: startDate, endDate: endDate)
        XCTAssertTrue(dates.count == 2)
        XCTAssertTrue(dates[0] == startDate)
        XCTAssertTrue(floor(dates[1].timeIntervalSince1970) == floor(endDate.timeIntervalSince1970))
    }
    
    func testGeneratePickerDatesForDailyWithWeekEndDate() {
        let recurrence: Date.Recurrence = .daily
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(24*3600*7)
        let dates = viewModel.datesForRecurrence(recurrence, startDate: startDate, endDate: endDate)
        XCTAssertTrue(dates.count == 8)
        XCTAssertTrue(dates[0] == startDate)
        XCTAssertTrue(floor(dates.last?.timeIntervalSince1970 ?? 0) == floor(endDate.timeIntervalSince1970))
    }
}
