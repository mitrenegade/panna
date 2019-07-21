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
        navigationItem.title = "Other Players"
        
        activityOverlay.show()
        load() { [weak self] in
            // filter out players already in the league
            self?.objects = (self?.objects ?? []).filter{ self?.roster[$0.id] == nil }
            self?.search(for: nil)
            self?.activityOverlay.hide()
        }
    }
}

extension PlayersListViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LeaguePlayerCell", for: indexPath) as! LeaguePlayerCell
        cell.reset()
        let section = sections[indexPath.section]
        let array = section.objects
        if indexPath.row < array.count, let player = array[indexPath.row] as? Player {
            cell.configure(player: player, status: .none)
        }
        return cell
    }
}
