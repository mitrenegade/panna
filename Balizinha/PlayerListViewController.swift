//
//  ListViewController.swift
//  Panna
//
//  Created by Bobby Ren on 6/17/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha
import Firebase

class PlayerListViewController: ListViewController {
    var players: [Player] = []
    var roster: [Membership]?

    fileprivate let activityOverlay: ActivityIndicatorOverlay = ActivityIndicatorOverlay()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.title = "Players"
    }
    
    override func load() {
        loadRoster()
    }
    
    func loadRoster() {
        activityOverlay.show()
        
        guard let league = league else { return }
        LeagueService.shared.memberships(for: league) { [weak self] (results) in
            self?.roster = results
            self?.observePlayers()
            DispatchQueue.main.async {
                self?.activityOverlay.hide()
            }
        }
    }
    
    func observePlayers() {
        DispatchQueue.main.async {
            self.activityOverlay.show()
        }
        players.removeAll()
        let dispatchGroup = DispatchGroup()
        for membership in roster ?? [] {
            let playerId = membership.playerId
            guard membership.isActive else { continue }
            dispatchGroup.enter()
            print("Loading player id \(playerId)")
            PlayerService.shared.withId(id: playerId, completion: {[weak self] (player) in
                if let player = player {
                    print("Finished player id \(playerId)")
                    self?.players.append(player)
                }
                dispatchGroup.leave()
            })
        }
        dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
            self?.players.sort(by: { (p1, p2) -> Bool in
                guard let t1 = p1.createdAt else { return false }
                guard let t2 = p2.createdAt else { return true}
                return t1 > t2
            })
            self?.reloadTable()
            self?.activityOverlay.hide()
        }
    }
}

extension PlayerListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return players.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell", for: indexPath) as! PlayerCell
        if indexPath.row < players.count {
            let player = players[indexPath.row]
            cell.configure(player: player, expanded: false)
        } else {
            cell.reset()
        }
        return cell
    }
}

extension PlayerListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
        guard indexPath.row < players.count else { return }
        let controller = UIStoryboard(name: "Account", bundle: nil).instantiateViewController(withIdentifier: "PlayerViewController") as! PlayerViewController
        controller.player = players[indexPath.row]
        navigationController?.pushViewController(controller, animated: true)
    }
}
