//
//  LeaguePlayersViewController.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 5/7/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit

import Firebase

protocol LeaguePlayersDelegate: class {
    func didUpdateRoster()
}

class LeaguePlayersViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
//    var roster: [Membership]?
    var league: League?
    var isEditOrganizerMode: Bool {
        return false // TODO: return true if user is an organizer?
    }
    var searchTerm: String?
    weak var delegate: LeaguePlayersDelegate?
    
    fileprivate let sections = ["Organizers", "Members", "Add a Player", "Players"]
    
    fileprivate var members: [Membership] {
        guard let players = roster else { return [] }
        return players.filter() { $0.isActive && !$0.isOrganizer }
    }
    fileprivate var organizers: [Membership] {
        guard let players = roster else { return [] }
        return players.filter() { return $0.isOrganizer }
    }
    fileprivate var allPlayers: [Player] = []
    fileprivate var filteredPlayers: [Player] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isEditOrganizerMode {
            // only allowed to toggle current organizers
            navigationItem.title = "Edit Organizers"
        } else {
            // only allowed to add/remove players
            navigationItem.title = "Players"
        }
        
        load()
    }
    
    func reloadTableData() {
        tableView.reloadData()
    }
    
    func load() {
        showLoadingIndicator()
        let playerRef = firRef.child("players").queryOrdered(byChild: "createdAt")
        playerRef.observe(.value) {[weak self] (snapshot) in
            guard snapshot.exists() else {
                self?.hideLoadingIndicator()
                return
            }
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                self?.allPlayers.removeAll()
                for playerDict: DataSnapshot in allObjects {
                    let player = Player(snapshot: playerDict)
                    self?.allPlayers.append(player)
                }
                self?.allPlayers.sort(by: { (p1, p2) -> Bool in
                    guard let t1 = p1.createdAt else { return false }
                    guard let t2 = p2.createdAt else { return true}
                    return t1 > t2
                })
                self?.search(for: nil)
//                self?.hideLoadingIndicator()
                self?.reloadTableData()
            }
        }
    }
}

extension LeaguePlayersViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if isEditOrganizerMode {
            return 2
        }
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case "Organizers":
            return organizers.count
        case "Members":
            return members.count
        case "Add a Player":
            return 1
        case "Players":
            return filteredPlayers.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
//        switch sections[section] {
//        case "Organizers", "Members", "Add a Player":
//            return sections[section]
//        case "Players":
//            if !filteredPlayers.isEmpty {
//            } else {
//                return nil
//            }
//        default:
//            return nil
//        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section] {
        case "Organizers", "Members":
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeaguePlayerCell", for: indexPath) as! LeaguePlayerCell
            let array: [Membership]
            let status: String
            if indexPath.section == 0 {
                array = organizers
                status = Membership.Status.organizer.rawValue
            } else {
                array = members
                status = Membership.Status.member.rawValue
            }
            cell.reset()
            if indexPath.row < array.count {
                let playerId = array[indexPath.row].playerId
                PlayerService.shared.withId(id: playerId) { (player) in
                    if let player = player {
                        DispatchQueue.main.async {
                            cell.configure(player: player, status: status)
                        }
                    }
                }
            }
            return cell
        case "Add a Player":
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerSearchCell", for: indexPath) as! PlayerSearchCell
            cell.delegate = self
            return cell
        case "Players":
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeaguePlayerCell", for: indexPath) as! LeaguePlayerCell
            if indexPath.row < filteredPlayers.count {
                let player = filteredPlayers[indexPath.row]
                let status: Membership.Status
                if let roster = roster {
                    let member = roster.filter() { $0.playerId == player.id }.first
                    status = member?.status ?? .none
                } else {
                    status = .none
                }
                cell.configure(player: player, status: status.rawValue)
            }
            return cell
        default:
            return UITableViewCell()
        }
    }
}

extension LeaguePlayersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if isEditOrganizerMode {
            switch sections[indexPath.section] {
            case "Organizers", "Members":
                if isEditOrganizerMode {
                    toggleOrganizerStatus(indexPath: indexPath)
                }
            default:
                return
            }
        } else {
            guard let roster = roster else { return }
            guard let league = league else { return }

            switch sections[indexPath.section] {
            case "Members" :
                guard indexPath.row < roster.count else { return }
                let newStatus: Membership.Status = .none
                let member = roster[indexPath.row]
                showLoadingIndicator()
                LeagueService.shared.changeLeaguePlayerStatus(playerId: member.playerId, league: league, status: newStatus.rawValue, completion: { [weak self] (result, error) in
                    print("Result \(result) error \(error)")
                    if result != nil {
                        guard let roster = self?.roster else { return }
                        self?.roster = (roster.filter() { $0.playerId != member.playerId })
                        self?.roster?.append(Membership(id: member.playerId, status: newStatus.rawValue))
                    }
                    DispatchQueue.main.async {
                        self?.hideLoadingIndicator()
                        self?.search(for: self?.searchTerm)
                        self?.delegate?.didUpdateRoster()
                    }
                })
                break
            case "Players":
                print("Updating player")
                guard indexPath.row < filteredPlayers.count else { return }
                let player = filteredPlayers[indexPath.row]
                let newStatus: Membership.Status = .member
                showLoadingIndicator()
                LeagueService.shared.changeLeaguePlayerStatus(playerId: player.id, league: league, status: newStatus.rawValue, completion: { [weak self] (result, error) in
                    print("Result \(result) error \(error)")
                    if result != nil {
                        guard let roster = self?.roster else { return }
                        self?.roster = (roster.filter() { $0.playerId != player.id })
                        self?.roster?.append(Membership(id: player.id, status: newStatus.rawValue))
                    }
                    DispatchQueue.main.async {
                        self?.hideLoadingIndicator()
                        self?.search(for: self?.searchTerm)
                        self?.delegate?.didUpdateRoster()
                    }
                })
            default:
                return
            }
        }
    }
    
    fileprivate func toggleOrganizerStatus(indexPath: IndexPath) {
        guard let league = league else { return }
        let newStatus: String
        let title: String
        let message: String
        let playerId: String
        if indexPath.section == 0 {
            guard indexPath.row < organizers.count else { return }
            playerId = organizers[indexPath.row].playerId
            newStatus = Membership.Status.member.rawValue
            title = "Demote player?"
            message = "This player is an organizer. Do you want to remove them?"
        } else {
            guard indexPath.row < members.count else { return }
            playerId = members[indexPath.row].playerId
            newStatus = Membership.Status.organizer.rawValue
            title = "Promote player?"
            message = "Do you want this player to become an organizer?"
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            print("Switching player \(playerId) to status \(newStatus)")
            self.showLoadingIndicator()
            LeagueService.shared.changeLeaguePlayerStatus(playerId: playerId, league: league, status: newStatus, completion: { [weak self] (result, error) in
                print("Result \(result) error \(error)")
                if result != nil {
                    guard let roster = self?.roster else { return }
                    self?.roster = (roster.filter() { $0.playerId != playerId })
                    self?.roster?.append(Membership(id: playerId, status: newStatus))
                }
                DispatchQueue.main.async {
                    self?.hideLoadingIndicator()
                    self?.search(for: self?.searchTerm)
                    self?.delegate?.didUpdateRoster()
                }
            })
        }))
        present(alert, animated: true, completion: nil)
    }
}

extension LeaguePlayersViewController: PlayerSearchDelegate {
    func search(for string: String?) {
        print("Search for string \(string)")
        
        // filter for search string; if string is nil, uses all players
        searchTerm = string
        if let currentSearch = searchTerm {
            filteredPlayers = allPlayers.filter() {
                let nameMatch = $0.name?.contains(currentSearch) ?? false
                let emailMatch = $0.email?.contains(currentSearch) ?? false
                let idMatch = $0.id.contains(currentSearch)
                return nameMatch || emailMatch || idMatch
            }
        } else {
            filteredPlayers = allPlayers
        }
        
        // filter for membership
        filteredPlayers = filteredPlayers.filter({ (p) -> Bool in
            let contains = members.filter({ (m) -> Bool in
                return m.playerId == p.id
            })
            return contains.first == nil
        })
        
        reloadTableData()
    }
}
