//
//  PromoCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 10/2/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

class PromoCell: UITableViewCell {
    
    var canAddPromotion: Bool = false
    func reset() {
        self.textLabel?.text = "No current promotion"
        self.detailTextLabel?.text = "Click to enter a promo code"
        canAddPromotion = true
    }
    
    func configure() {
        guard let current = PlayerService.shared.current, let promoId = current.promotionId else {
            self.reset()
            return
        }

        self.textLabel?.text = "Loading promotion"
        self.detailTextLabel?.text = nil
        let promotionRef = firRef.child("promotions").child(promoId)
        promotionRef.observeSingleEvent(of: .value) { (snapshot: DataSnapshot?) in
            if let snapshot = snapshot {
                let promotion = Promotion(snapshot: snapshot)
                self.textLabel?.text = "Current promo: \(promotion.id)"
                self.detailTextLabel?.text = promotion.info
            }
            else {
                self.reset()
            }
        }
    }

}
