//
//  LeagueInfoCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 6/24/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class LeagueInfoCell: UITableViewCell {

    @IBOutlet weak var labelInfo: UILabel!
    @IBOutlet weak var constraintHeight: NSLayoutConstraint!
    
    func configure(league: League?) {
        guard let league = league else { return }
        let infoText = league.info
        labelInfo.text = infoText
        
        let size = (infoText as NSString).boundingRect(with: CGSize(width: labelInfo.frame.size.width, height: self.frame.size.height), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: labelInfo.font], context: nil)
        constraintHeight.constant = size.height
    }
}
