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
    @IBOutlet weak var constraintBottomOffset: NSLayoutConstraint!
    var league: League?
    var isEditOrganizerMode: Bool = false // TODO: not used yet
    var searchTerm: String?
    weak var delegate: LeaguePlayersDelegate?
    
    // search/filter
    @IBOutlet weak var containerSearch: UIView!
    @IBOutlet weak var inputSearch: UITextField!
    @IBOutlet weak var buttonSearch: UIButton!
    
    fileprivate let sections = ["Organizers", "Members", "Players"]
    fileprivate var allPlayers: [Player] = []
    fileprivate var memberships: [String: Membership.Status] = [:]
    var roster: [Membership]? {
        didSet {
            if let roster = roster {
                for membership in roster {
                    memberships[membership.playerId] = membership.status
                }
            } else {
                memberships.removeAll()
            }
        }
    }
    
    // lists filtered based on search and membership
    fileprivate var members: [String] = [] // all members including organizers
    fileprivate var organizers: [String] = []
    fileprivate var players: [String] = [] // non-members
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isEditOrganizerMode {
            // only allowed to toggle current organizers
            navigationItem.title = "Edit Organizers"
        } else {
            // only allowed to add/remove players
            navigationItem.title = "Players"
        }
        
        loadFromRef()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func reloadTableData() {
        tableView.reloadData()
    }

    func loadFromRef() { // loads all players, using observed player endpoint
        let playerRef = firRef.child("players").queryOrdered(byChild: "createdAt")
        playerRef.observe(.value) {[weak self] (snapshot) in
            guard snapshot.exists() else {
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
                self?.reloadTableData()
            }
        }
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        let userInfo:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        constraintBottomOffset.constant = keyboardHeight
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        self.constraintBottomOffset.constant = 0
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
        case "Players":
            return players.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let name = sections[section]
        switch sections[section] {
        case "Organizers":
            return "\(name) - \(organizers.count)"
        case "Members":
            return "\(name) - \(members.count)"
        case "Players":
            return "\(name) - \(players.count)"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LeaguePlayerCell", for: indexPath) as! LeaguePlayerCell
        let array: [String]
        let status: Membership.Status
        switch sections[indexPath.section] {
        case "Organizers":
            array = organizers
            status = Membership.Status.organizer
        case "Members":
            array = members
            status = Membership.Status.member
        case "Players":
            array = players
            status = Membership.Status.none
        default:
            return cell
        }
        cell.reset()
        if indexPath.row < array.count {
            let playerId = array[indexPath.row]
            PlayerService.shared.withId(id: playerId) { (player) in
                if let player = player {
                    DispatchQueue.main.async {
                        cell.configure(player: player, status: status)
                    }
                }
            }
        }
        return cell
        
    }
}

extension LeaguePlayersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let league = league else { return }
        let newStatus: Membership.Status
        let playerId: String
        
        switch sections[indexPath.section] {
        case "Organizers":
            guard indexPath.row < organizers.count else { return }
            playerId = organizers[indexPath.row]
            newStatus = .member
        case "Members" :
            guard indexPath.row < members.count else { return }
            playerId = members[indexPath.row]
            if isEditOrganizerMode {
                newStatus = .organizer
            } else {
                newStatus = .none
            }
        case "Players":
            guard indexPath.row < players.count else { return }
            playerId = players[indexPath.row]
            newStatus = .member
        default:
            return
        }
        
        // cache old value in case of failure, to revert
        let oldStatus = memberships[playerId]
        
        // update first before web request returns
        memberships[playerId] = newStatus
        search(for: searchTerm)
        
        LeagueService.shared.changeLeaguePlayerStatus(playerId: playerId, league: league, status: newStatus.rawValue, completion: { [weak self] (result, error) in
            print("Result \(result) error \(error)")
            if let error = error as? NSError {
                self?.memberships[playerId] = oldStatus
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

// MARK: - Search
extension LeaguePlayersViewController {
    @IBAction func didClickSearch(_ sender: Any?) {
        search(for: inputSearch.text)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        didClickSearch(nil)
        return true
    }
    
    func search(for string: String?) {
        print("Search for string \(string)")
        
        // filter for search string; if string is nil, uses all players
        searchTerm = string
        var filteredPlayers: [Player] = []
        if let currentSearch = searchTerm?.lowercased(), !currentSearch.isEmpty {
            filteredPlayers = allPlayers.filter() { player in
                let nameMatch = player.name?.lowercased().contains(currentSearch) ?? false
                let emailMatch = player.email?.lowercased().contains(currentSearch) ?? false
                let idMatch = player.id.lowercased().contains(currentSearch)
                return nameMatch || emailMatch || idMatch
            }
        } else {
            filteredPlayers = allPlayers
        }
        
        // filter for membership
        organizers = filteredPlayers.compactMap({ (player) -> String? in
            return memberships[player.id] == Membership.Status.organizer ? player.id : nil
        })
        members = filteredPlayers.compactMap({ (player) -> String? in
            return memberships[player.id] == Membership.Status.member ? player.id : nil
        })
        players = filteredPlayers.compactMap({ (player) -> String? in
            return (memberships[player.id] == nil || memberships[player.id] == Membership.Status.none) ? player.id : nil
        })
        
        reloadTableData()
    }
}
