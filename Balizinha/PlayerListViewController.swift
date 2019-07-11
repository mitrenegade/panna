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

class PlayerListViewController: SearchableListViewController {
    var roster: [Membership]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.title = "Players"
    }
    
    override func load(completion:(()->Void)? = nil) {
        loadRoster(completion: completion)
    }
    
    func loadRoster(completion:(()->Void)? = nil) {
        activityOverlay.show()
        
        guard let league = league else { return }
        LeagueService.shared.memberships(for: league) { [weak self] (results) in
            self?.roster = results
            self?.observePlayers()
            DispatchQueue.main.async {
                self?.activityOverlay.hide()
                completion?()
            }
        }
    }
    
    func observePlayers() {
        DispatchQueue.main.async {
            self.activityOverlay.show()
        }
        objects.removeAll()
        let dispatchGroup = DispatchGroup()
        for membership in roster ?? [] {
            let playerId = membership.playerId
            guard membership.isActive else { continue }
            dispatchGroup.enter()
            print("Loading player id \(playerId)")
            PlayerService.shared.withId(id: playerId, completion: {[weak self] (player) in
                if let player = player {
                    print("Finished player id \(playerId)")
                    self?.objects.append(player)
                }
                dispatchGroup.leave()
            })
        }
        dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
            self?.objects.sort(by: { (p1, p2) -> Bool in
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
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LeaguePlayerCell", for: indexPath) as! LeaguePlayerCell
        if indexPath.row < objects.count, let player = objects[indexPath.row] as? Player {
            // TODO: include player status in league
            cell.configure(player: player, status: nil)
        } else {
            cell.reset()
        }
        return cell
    }
}

extension PlayerListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
        guard indexPath.row < objects.count else { return }
        let controller = UIStoryboard(name: "Account", bundle: nil).instantiateViewController(withIdentifier: "PlayerViewController") as! PlayerViewController
        controller.player = objects[indexPath.row] as? Player
        navigationController?.pushViewController(controller, animated: true)
    }
}
