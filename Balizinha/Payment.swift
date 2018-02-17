//
//  Payment.swift
//  Balizinha
//
//  Created by Bobby Ren on 9/26/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

class Payment: FirebaseBaseModel {
    var amount: NSNumber? {
        return self.dict["amount"] as? NSNumber
    }

    var refunded: NSNumber? {
        return self.dict["amount_refunded"] as? NSNumber
    }
    
    var paid: Bool {
        return self.dict["paid"] as? Bool ?? false
    }
    
    var playerId: String? {
        return self.dict["player_id"] as? String
    }
    
    enum Status: String {
        case succeeded
        case error
        case active // subscription
        case unknown
    }
    
    var status: Payment.Status {
        guard let string = self.dict["status"] as? String else {
            if error != nil {
                return .error
            }
            return .unknown
        }
        guard let newStatus = Status(rawValue: string) else { return .unknown }
        return newStatus
    }
    
    var error: String? {
        return self.dict["error"] as? String
    }

    var createdAt: Date? {
        if let val = self.dict["created"] as? TimeInterval {
            let time1970: TimeInterval = 1517606802
            if val > time1970 * 10.0 {
                return Date(timeIntervalSince1970: (val / 1000.0))
            } else {
                return Date(timeIntervalSince1970: val)
            }
        }
        return nil
    }
    
    var amountString: String? {
        guard let number = amount else { return nil }
        return currencyFormatter.string(from: NSNumber(value: number.doubleValue / 100) )
    }
    
    fileprivate var currencyFormatter: NumberFormatter {
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
