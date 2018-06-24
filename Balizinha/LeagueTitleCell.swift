//
//  LeagueTitleCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 6/24/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import AsyncImageView

class LeagueTitleCell: UITableViewCell {
    @IBOutlet weak var logoView: AsyncImageView!
    @IBOutlet weak var labelCity: UILabel!
    @IBOutlet weak var labelName: UILabel!
    
    func configure(league: League?) {
        guard let league = league else { return }
        labelCity.text = league.city
        labelName.text = league.name
        if let url = league.photoUrl {
            logoView.imageURL = URL(string: url)
        }
    }
}
