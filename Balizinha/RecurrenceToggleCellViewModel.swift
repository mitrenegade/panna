//
//  RecurrenceToggleCellViewModel.swift
//  Panna
//
//  Created by Bobby Ren on 9/12/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import UIKit

struct RecurrenceToggleCellViewModel {
    func datesForRecurrence(_ recurrence: Date.Recurrence, startDate: Date, endDate: Date) -> [Date] {
        guard recurrence != .none else {
            return [startDate]
        }
        guard endDate > startDate else {
            return []
        }
        var dates: [Date] = []
        var date: Date = startDate
        while date < endDate {
            dates.append(date)
            guard let nextDate = date.getNextRecurrence(recurrence: recurrence, from: date) else { break }
            date = nextDate
        }
        
        return dates
    }
}
