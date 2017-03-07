//
//  String+Utils.swift
//  rollcall
//
//  Created by Bobby Ren on 2/7/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation

extension String {
    func isValidEmail() -> Bool {
        // http://stackoverflow.com/questions/25471114/how-to-validate-an-e-mail-address-in-swift
        let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }
}

extension Date {
    func dateString() -> String {
        return "\((self as NSDate).day()) \(months[(self as NSDate).month() - 1]) \((self as NSDate).year())"
    }
}
