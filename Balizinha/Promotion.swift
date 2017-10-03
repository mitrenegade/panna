//
//  Promotion.swift
//  Balizinha
//
//  Created by Bobby Ren on 10/2/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

enum PromotionType: String {
    case percentDiscount
    case unknown
}

class Promotion: FirebaseBaseModel {
    // promo model:
    // info: "You are a preferred member"
    // type: percentDiscount
    // active: true, false if player switches ids or is removed from the program
    // value: 50
    
    var info: String? {
        return self.dict["info"] as? String
    }
    
    var type: PromotionType? {
        guard let typeString = self.dict["type"] as? String else { return .unknown }
        return PromotionType.init(rawValue: typeString)
    }
    
    var active: Bool {
        return self.dict["active"] as? Bool ?? false
    }
    
    var value: NSNumber? {
        return self.dict["value"] as? NSNumber
    }
    
    var code: String {
        return self.id
    }

//    var playerId: String? {
//        return self.dict["playerId"] as? String
//    }
//    
//    var easyCode: String {
//        if let value = self.dict["easyCode"] as? String {
//            return value
//        }
//        return self.id
//    }
}
