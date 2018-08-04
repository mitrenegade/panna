//
//  PromoCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 10/2/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseCommunity

class PromoCell: UITableViewCell {

    var canAddPromotion: Bool = false
    func reset() {
        self.textLabel?.text = "No current promotion"
        self.detailTextLabel?.text = "Click to enter a promo code"
        canAddPromotion = true
    }
    
    func configure() {
        guard let current = PlayerService.shared.current.value, let promoId = current.promotionId else {
            self.reset()
            return
        }

        self.textLabel?.text = "Loading promotion"
        self.detailTextLabel?.text = nil
        PromotionService.shared.withId(id: promoId) { (promotion, error) in
            if let promotion = promotion {
                self.textLabel?.text = "Current promo: \(promotion.id)"
                self.detailTextLabel?.text = promotion.info
            }
            else {
                self.reset()
            }
        }
    }

}
