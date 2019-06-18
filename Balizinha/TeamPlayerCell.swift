//
//  TeamPlayerCell.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 2/6/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha

class TeamPlayerCell: LeaguePlayerCell {
    @IBOutlet weak var labelTeam: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        labelTeam.layer.borderWidth = 1
        labelTeam.layer.cornerRadius = labelTeam.frame.size.width / 2
        labelTeam.layer.borderColor = UIColor.black.cgColor
    }

    func configure(player: Player, team: Int?) {
        super.configure(player: player, status: .none)

        if let team = team {
            labelTeam.isHidden = false
            labelTeam.text = "\(team)"
        } else {
            labelTeam.isHidden = true
        }
    }
}
