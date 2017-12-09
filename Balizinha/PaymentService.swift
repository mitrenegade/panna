//
//  PaymentService.swift
//  Balizinha
//
//  Created by Bobby Ren on 12/6/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

class PaymentService: NSObject {
    func checkForPayment(for eventId: String, by playerId: String, completion:@escaping ((Bool)->Void)) {
        let ref = firRef.child("charges/events/\(eventId)")
        ref.observe(.value) { (snapshot: DataSnapshot) in
            guard let payments = snapshot.value as? [String: [String: Any]] else {
                completion(false)
                return
            }
            for (_, info) in payments {
                if let player_id = info["player_id"] as? String, playerId == player_id {
                    completion(true)
                    return
                }
            }
            completion(false)
        }
    }
}
