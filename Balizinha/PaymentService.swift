//
//  PaymentService.swift
//  Balizinha
//
//  Created by Bobby Ren on 12/6/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseCommunity
import Stripe
import Balizinha

class PaymentService: NSObject {
    func checkForPayment(for eventId: String, by playerId: String, completion:@escaping ((Bool)->Void)) {
        let ref = firRef.child("charges/events/\(eventId)")
        print("checking for payment on \(ref)")
        ref.observeSingleEvent(of: .value) { (snapshot: DataSnapshot) in
            guard snapshot.exists(), let payments = snapshot.value as? [String: [String: Any]] else {
                completion(false)
                return
            }
            for (_, info) in payments {
                if let player_id = info["player_id"] as? String, playerId == player_id, let status = info["status"] as? String, status == "succeeded", let refund = info["refunded"] as? Double, refund == 0 {
                    completion(true)
                    return
                }
            }
            completion(false)
        }
    }
    
    class func savePaymentInfo(_ paymentMethod: STPPaymentMethod) {
        guard let player = PlayerService.shared.current.value else { return }
        guard let card = paymentMethod as? STPCard else { return }

        let params: [String: Any] = ["userId": player.id, "source": card.stripeID, "last4":card.last4, "label": card.label]
        FirebaseAPIService().cloudFunction(functionName: "savePaymentInfo", method: "POST", params: params) { (result, error) in
            print("FirebaseAPIService: savePaymentInfo result \(result) error \(error)")
        }
    }
}
