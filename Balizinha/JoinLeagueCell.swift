//
//  JoinLeagueCell.swift
//  Balizinha
//
//  Created by Ren, Bobby on 7/14/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

protocol JoinLeagueDelegate: class {
    func clickedJoinLeague(_ league: League)
}

class JoinLeagueViewModel {
    let league: League
    
    init(league: League) {
        self.league = league
    }
    
    var buttonText: String? {
        if LeagueService.shared.playerIsIn(league: league) {
            // leave league
            return "Leave league"
        } else {
            // join league
            if league.isPrivate {
                return "League is private"
            } else {
                return "Join league"
            }
        }
    }
    
    var buttonEnabled: Bool {
        if LeagueService.shared.playerIsIn(league: league) {
            // leave league
            return true
        } else {
            // join league
            if league.isPrivate {
                return false
            } else {
                return true
            }
        }

    }
}
class JoinLeagueCell: UITableViewCell {
    @IBOutlet weak var buttonJoin: UIButton!
    weak var league: League?
    var viewModel: JoinLeagueViewModel?
    
    weak var delegate: JoinLeagueDelegate?
    var requestInProgress: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(league: League?) {
        self.league = league
        if let league = league {
            self.viewModel = JoinLeagueViewModel(league: league)
        }
        refresh()
    }
    
    func refresh() {
        guard let viewModel = viewModel else { return }
        buttonJoin.setTitle(viewModel.buttonText, for: .normal)
        
        buttonJoin.isEnabled = !requestInProgress && viewModel.buttonEnabled
        buttonJoin.alpha = (!requestInProgress && viewModel.buttonEnabled) ? 1.0 : 0.5
    }

    @IBAction func didClickJoin(_ sender: Any?) {
        guard let league = league else { return }
        delegate?.clickedJoinLeague(league)
        requestInProgress = true
        refresh()
    }
    
    func reset() {
        requestInProgress = false
        refresh()
    }
}
