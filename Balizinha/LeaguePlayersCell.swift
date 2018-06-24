//
//  LeaguePlayersCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 6/24/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class LeaguePlayersCell: UITableViewCell {

    @IBOutlet weak var playersView: PlayersScrollView!

    func configure(players: [Player]?) {
        guard let players = players else { return }
        playersView.reset()
        for player in players {
            playersView.addPlayer(player: player)
        }
        
        playersView.refresh()
    }
}
