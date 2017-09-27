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
}
