//
//  PlayersListViewController.swift
//  Panna
//
//  Created by Bobby Ren on 7/21/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//
import UIKit
import Balizinha
import Firebase
import RenderCloud

protocol PlayersListDelegate: class {
    func didSelectPlayer(_ player: Player)
}

class PlayersListViewController: SearchableListViewController {
    var roster: [String:Membership] = [:]
    weak var delegate: PlayersListDelegate?

    override var sections: [Section] {
        return [("Players", objects)]
    }
    
    override var refName: String {
        return "players"
    }
    
    override func createObject(from snapshot: Snapshot) -> FirebaseBaseModel? {
        return Player(snapshot: snapshot)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.title = "Players"
        
        activityOverlay.show()
        load() { [weak self] in
            // TODO: filter out players already in the league
            self?.search(for: nil)
            self?.activityOverlay.hide()
        }
    }
}
