//
//  LeaguePlayersCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 6/24/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class LeaguePlayersCell: UITableViewCell {

    @IBOutlet weak var playersView: PlayersScrollView!
    weak var delegate: PlayersScrollViewDelegate?
    @IBOutlet weak var constraintEditPlayerHeight: NSLayoutConstraint!
    var handleAddPlayers: (()->Void)?
    var roster: [Membership]?

    func configure(players: [Player]?) {
        playersView.delegate = delegate
        
        playersView.reset()
        
        guard let players = players else { return }
        for player in players {
            playersView.addPlayer(player: player)
        }
        
        playersView.refresh()
        
        // organizer is allowed to edit players
        let isOrganizer = roster?.filter() { $0.playerId == PlayerService.shared.current.value?.id }.first?.isOrganizer ?? AIRPLANE_MODE
        constraintEditPlayerHeight.constant = isOrganizer ? 30 : 0
    }
    
    @IBAction func didClickAddPlayers(_ sender: Any?) {
        handleAddPlayers?()
    }
}
