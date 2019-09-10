//
//  Date+Utils.swift
//  Balizinha
//
//  Created by Bobby Ren on 10/9/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation

extension Date {
    func dateString() -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: self)
        let month = calendar.component(.month, from: self)
        let year = calendar.component(.year, from: self)
        //return "\((self as NSDate).day()) \(months[(self as NSDate).month() - 1]) \((self as NSDate).year())"
        return "\(day) \(Date.months[month - 1]) \(year)"
    }
    
    // date picker
    func dateStringForPicker() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, MMM dd"
        //dateFormatter.dateStyle = DateFormatter.Style.medium
        //dateFormatter.timeStyle = DateFormatter.Style.none
        return dateFormatter.string(from: self)
    }
    
    // start and end time picker
    func timeStringForPicker() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.none
        dateFormatter.timeStyle = DateFormatter.Style.short
        return dateFormatter.string(from: self)
    }
}
