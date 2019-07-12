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
    var roster: [String:Membership] = [:]
    var leagueOrganizers: [Player] = []
    var leagueMembers: [Player] = []
    override var sections: [Section] {
        return [("Organizers", leagueOrganizers), ("Members", leagueMembers)]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.title = "Players"
        
        activityOverlay.show()
        load() { [weak self] in
            self?.search(for: nil)
            self?.activityOverlay.hide()
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(didClickCancel(_:)))
    }
    
    override func load(completion:(()->Void)? = nil) {
        activityOverlay.show()
        
        guard let league = league else { return }
        objects.removeAll()
        roster.removeAll()
        LeagueService.shared.memberships(for: league) { [weak self] (results) in
            let dispatchGroup = DispatchGroup()
            for membership in results ?? [] {
                let playerId = membership.playerId
                guard membership.isActive else { continue }
                self?.roster[playerId] = membership
                
                dispatchGroup.enter()
                PlayerService.shared.withId(id: playerId, completion: {[weak self] (player) in
                    if let player = player {
                        print("Finished player id \(playerId) name \(player.name) status \(membership.status)")
                        self?.objects.append(player)
                    }
                    dispatchGroup.leave()
                })
            }
            dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
                completion?()
            }
        }
    }
}

extension PlayerListViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LeaguePlayerCell", for: indexPath) as! LeaguePlayerCell
        cell.reset()
        let section = sections[indexPath.section]
        let array = section.objects
        if indexPath.row < array.count {
            if let player = array[indexPath.row] as? Player {
                let status = roster[player.id]?.status ?? .none
                cell.configure(player: player, status: status)
            }
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

// search and filtering
extension PlayerListViewController {
    @objc override func updateSections(_ newObjects: [FirebaseBaseModel]) {
        var players = newObjects.compactMap { $0 as? Player }
        players.sort(by: { (p1, p2) -> Bool in
            guard let t1 = p1.createdAt else { return false }
            guard let t2 = p2.createdAt else { return true}
            return t1 > t2
        })
        
        leagueOrganizers = players.filter {
            print("Filtering for player \($0.name) \(roster[$0.id]?.status)")
            return roster[$0.id]?.status == Membership.Status.organizer }
        leagueMembers = players.filter { return roster[$0.id]?.status == Membership.Status.organizer }
    }
    
    override func doFilter(_ currentSearch: String) -> [FirebaseBaseModel] {
        return objects.filter {(_ object: FirebaseBaseModel) in
            guard let player = object as? Player else { return false }
            let nameMatch = player.name?.lowercased().contains(currentSearch) ?? false
            let emailMatch = player.email?.lowercased().contains(currentSearch) ?? false
            let idMatch = player.id.lowercased().contains(currentSearch)
            return nameMatch || emailMatch || idMatch
        }
    }
}
