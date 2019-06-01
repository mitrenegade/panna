//
//  SubscriptionCell.swift
//  Panna
//
//  Created by Bobby Ren on 6/1/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class SubscriptionCell: LeagueCell {
    @IBOutlet weak var labelSubsciptionStatus: UILabel!
    @IBOutlet weak var labelAmount: UILabel!

    func configure(league: League, subscription: Subscription) {
        super.configure(league: league)
        
        labelSubsciptionStatus.text = subscription.status
        labelAmount.text = EventService.amountString(from: NSNumber(value: subscription.amount ?? 0))
    }
}

