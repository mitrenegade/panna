//
//  LeagueInfoCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 6/24/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class LeagueInfoCell: UITableViewCell {

    @IBOutlet weak var textViewInfo: UITextView!
    @IBOutlet weak var constraintHeight: NSLayoutConstraint!
    
    func configure(league: League?) {
        guard let league = league else { return }
        let infoText = league.info
        textViewInfo.text = infoText
        let size = textViewInfo.sizeThatFits(CGSize(width: textViewInfo.frame.size.width, height: self.frame.size.height))
        constraintHeight.constant = size.height
    }
}
