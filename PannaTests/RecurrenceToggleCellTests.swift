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
        cell.selectRecurrence(.none)
    }
    
    func testGeneratePickerDates() {
        let recurrence: Date.Recurrence = .none
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(1)
        let dates = viewModel.datesForRecurrence(recurrence, startDate: startDate, endDate: endDate)
        XCTAssertTrue(dates.count == 1)
        XCTAssertTrue(dates[0] == startDate)
    }
}
