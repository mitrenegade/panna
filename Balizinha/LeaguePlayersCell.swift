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
    weak var delegate: PlayersScrollViewDelegate?
    var handleAddPlayers: (()->Void)?

    func configure(players: [Player]?) {
        playersView.delegate = delegate
        
        guard let players = players else { return }
        for player in players {
            playersView.addPlayer(player: player)
        }
        
        playersView.refresh()
    }
    
    @IBAction func didClickAddPlayers(_ sender: Any?) {
        handleAddPlayers?()
    }
}
