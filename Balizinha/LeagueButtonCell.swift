//
//  JoinLeagueCell.swift
//  Balizinha
//
//  Created by Ren, Bobby on 7/14/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//
// used for join league and invite

import UIKit
import Balizinha

protocol LeagueButtonCellDelegate: class {
    func clickedLeagueButton(_ cell: LeagueButtonCell, league: League)
}

class LeagueButtonCellViewModel {
    let league: League
    
    init(league: League) {
        self.league = league
    }
    
    var buttonText: String? { return nil }
    var buttonEnabled: Bool { return false }
}

class JoinLeagueButtonViewModel: LeagueButtonCellViewModel {
    override var buttonText: String? {
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
    
    override var buttonEnabled: Bool {
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

class ShareLeagueButtonViewModel: LeagueButtonCellViewModel {
    override var buttonText: String? {
        return "Invite a friend"
    }
    
    override var buttonEnabled: Bool {
        if league.owner == PlayerService.shared.current.value?.id {
            return true
        }
        
        return !league.isPrivate
    }
}

class LeagueButtonCell: UITableViewCell {
    @IBOutlet weak var button: UIButton!
    weak var league: League?
    var viewModel: LeagueButtonCellViewModel?
    
    weak var delegate: LeagueButtonCellDelegate?
    var requestInProgress: Bool = false
    
    func configure(league: League?, viewModel: LeagueButtonCellViewModel?) {
        self.league = league
        self.viewModel = viewModel
        refresh()
    }
    
    func refresh() {
        guard let viewModel = viewModel else { return }
        button.setTitle(viewModel.buttonText, for: .normal)
        
        button.isEnabled = !requestInProgress && viewModel.buttonEnabled
        button.alpha = (!requestInProgress && viewModel.buttonEnabled) ? 1.0 : 0.5
    }

    @IBAction func didClick(_ sender: Any?) {
        guard let league = league else { return }
        delegate?.clickedLeagueButton(self, league: league)
        requestInProgress = true
        refresh()
    }
    
    func reset() {
        requestInProgress = false
        refresh()
    }
}
