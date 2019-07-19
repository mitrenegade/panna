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

protocol PlayerListDelegate: class {
    func didUpdateRoster()
}

class PlayerListViewController: SearchableListViewController {
    var roster: [String:Membership] = [:]
    var leagueOrganizers: [Player] = []
    var leagueMembers: [Player] = []
    override var sections: [Section] {
        return [("Organizers", leagueOrganizers), ("Members", leagueMembers)]
    }

    weak var delegate: PlayerListDelegate?
    
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
        
        let info: [String: Any] = ["leagueId": league?.id ?? ""]
        LoggingService.shared.log(event: .DashboardViewLeaguePlayers, info: info)
    }
    
    override func load(completion:(()->Void)? = nil) {
        guard !AIRPLANE_MODE else {
            objects = [MockService.mockPlayerOrganizer(), MockService.mockPlayerMember()]
            roster = ["1": Membership(id: "1", status: "organizer"), "2": Membership(id: "2", status: "member")]
            completion?()
            return
        }
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
                        self?.objects.append(player)
                    }
                    dispatchGroup.leave()
                })
            }
            dispatchGroup.notify(queue: DispatchQueue.main) {
                completion?()
            }
        }
    }
    
    // TODO
    func loadFromRef() { // loads all players, using observed player endpoint
        guard !AIRPLANE_MODE else {
            objects = [MockService.mockPlayerOrganizer(), MockService.mockPlayerMember()]
            search(for: nil)
            reloadTable()
            return
        }
        let playerRef = firRef.child("players").queryOrdered(byChild: "createdAt")
        playerRef.observe(.value) {[weak self] (snapshot) in
            guard snapshot.exists() else {
                return
            }
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                self?.objects.removeAll()
                for playerDict: DataSnapshot in allObjects {
                    let player = Player(snapshot: playerDict)
                    self?.objects.append(player)
                }
                self?.objects.sort(by: { (p1, p2) -> Bool in
                    guard let t1 = p1.createdAt else { return false }
                    guard let t2 = p2.createdAt else { return true}
                    return t1 > t2
                })
                self?.search(for: nil)
                self?.reloadTable()
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
        let section = sections[indexPath.section]
        guard indexPath.row < section.objects.count else { return }
        if let player: Player = section.objects[indexPath.row] as? Player {
            let controller = UIStoryboard(name: "Account", bundle: nil).instantiateViewController(withIdentifier: "PlayerViewController") as! PlayerViewController
            controller.player = player
            navigationController?.pushViewController(controller, animated: true)
        }
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
        
        leagueOrganizers = players.filter { return roster[$0.id]?.status == Membership.Status.organizer }
        leagueMembers = players.filter { return roster[$0.id]?.status == Membership.Status.member }
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

extension PlayerListViewController {
    func updateStatus(playerId: String, oldStatus: Membership.Status) {
        guard let league = league else { return }
        let newStatus: Membership.Status
        switch oldStatus {
        case .organizer:
            newStatus = .member
        case .member :
            // TODO: show alert
            newStatus = .organizer
//            newStatus = .none
        case .none:
            newStatus = .member
        default:
            return
        }
        
        // update first before web request returns
        let oldMembership = roster[playerId]
        roster[playerId] = Membership(id: playerId, status: oldStatus.rawValue)
        search(for: searchTerm)
        
        guard !AIRPLANE_MODE else {
            return
        }
        LeagueService.shared.changeLeaguePlayerStatus(playerId: playerId, league: league, status: newStatus.rawValue, completion: { [weak self] (result, error) in
            if let error = error as NSError? {
                self?.roster[playerId] = oldMembership
                DispatchQueue.main.async {
                    self?.simpleAlert("Update failed", defaultMessage: "Could not update status to \(newStatus.rawValue). ", error: error)
                }
            }
            DispatchQueue.main.async {
                self?.search(for: self?.searchTerm)
                self?.delegate?.didUpdateRoster()
            }
        })
    }
}
