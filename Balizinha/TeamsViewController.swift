//
//  TeamsViewController.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 2/6/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha
import MessageUI

class TeamsViewController: UIViewController {
    private let MAX_TEAMS = 12
    var players: [Player] = []
    var playerTeam: [String: Int] = [:]
    var event: Balizinha.Event?

    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Create Teams"
        refreshRightNavButton()

        simpleAlert("To create teams", message: "Click on players to manually assign them to teams. Click on Random to assign everyone else to teams. Up to 12 teams can be manually assigned. If no captains are selected, the order will be randomized. To remove a team assignment, swipe left.")
        
        players = randomizeOrder(oldPlayers: players)
    }
    
    func refreshRightNavButton() {
        if playerTeam.count == players.count {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: .done, target: self, action: #selector(didClickClear(_:)))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Random", style: .done, target: self, action: #selector(didClickRandom(_:)))
        }
    }
    
    @objc func didClickRandom(_ sender: Any) {
        if playerTeam.isEmpty {
            players = randomizeOrder(oldPlayers: players)
            tableView.reloadData()
        } else {
            fillRoster(allPlayers: players, playerTeams: playerTeam)
        }
        refreshRightNavButton()
    }
    
    @objc func didClickClear(_ sender: Any) {
        playerTeam.removeAll()
        tableView.reloadData()
        refreshRightNavButton()
    }
    
    // convenience function to list the players in a team
    func teamPlayers(team: Int) -> [Player] {
        return playerTeam.compactMap({ (playerId, playerTeam) -> Player? in
            if team == playerTeam {
                return players.first(where: {$0.id == playerId})
            } else {
                return nil
            }
        })
    }
    
    func randomizeOrder(oldPlayers: [Player]) -> [Player] {
        var newPlayers: [Player] = []
        var players = oldPlayers
        while let player = players.randomElement(), let index = players.firstIndex(of: player) {
            players.remove(at: index)
            newPlayers.append(player)
        }
        guard newPlayers.count == oldPlayers.count else {
            simpleAlert("Could not randomize", message: "There was a strange issue randomizing the whole list. There were \(oldPlayers.count) players but now there are \(newPlayers.count).")
            return oldPlayers
        }
        return newPlayers
    }
    
    func fillRoster(allPlayers: [Player], playerTeams: [String: Int]) {
        var players: [Player] = []
        var teams: Set<Int> = Set<Int>()
        
        // create list of teams, and list of players not on a team
        for player in allPlayers {
            if let team = playerTeams[player.id] {
                teams.insert(team)
            } else {
                players.append(player)
            }
        }
        
        // randomize remaining players
        let randomPlayers = randomizeOrder(oldPlayers: players)
        
        // insert each player into the lowest team count
        for player in randomPlayers {
            guard let newTeam = assignPlayer(player, teams: Array(teams)) else {
                simpleAlert("Could not assign player", message: "There was a strange issue assigning players. Currently there are \(randomPlayers.count) unassigned players and \(teams.count) existing teams")
                return
            }
            self.playerTeam[player.id] = newTeam
        }

        // reorder player list in team order
        let orderedTeams = Array(teams).sorted()
        var orderedPlayers: [Player] = []
        for team in orderedTeams {
            let squad = teamPlayers(team: team)
            orderedPlayers.append(contentsOf: squad)
        }
        self.players = orderedPlayers

        tableView.reloadData()
    }
    
    private func assignPlayer(_ player: Player, teams: [Int]) -> Int? {
        // find the team with the lowest count
        var currentMinTeamSize = 999
        var currentTeamNumber: Int?
        for team in teams {
            let playerCount = teamPlayers(team: team).count
            if playerCount < currentMinTeamSize {
                currentMinTeamSize = playerCount
                currentTeamNumber = team
            }
        }
        return currentTeamNumber
    }
    
    func sendEmail() {
        guard MFMailComposeViewController.canSendMail() else {
            simpleAlert("Cannot send email", message: "Your device is unable to send emails.")
            return
        }
        
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        
        // Configure the fields of the interface.
        let date: String = event?.startTime?.dateStringForPicker() ?? Date().dateStringForPicker()
        let name = event?.name ?? "Unnamed event"
        composeVC.setSubject("Team roster")
        var message = "Date: \(date)\nEvent: \(name)\n"
        
        // reorder player list in team order
        let orderedTeams = Array(Set(playerTeam.values)).sorted()
        if !orderedTeams.isEmpty {
            for team in orderedTeams {
                message = "\(message)\nTeam \(team)"
                let squad = teamPlayers(team: team)
                for player in squad {
                    let name = player.name ?? player.email ?? "Unknown name"
                    message = "\(message)\n\(name)"
                }
                message = message + "\n"
            }
        } else {
            for player in players {
                let name = player.name ?? player.email ?? "Unknown name"
                message = "\(message)\n\(name)"
            }
        }

        composeVC.setMessageBody(message, isHTML: false)
        
        // Present the view controller modally.
        present(composeVC, animated: true, completion: nil)
    }
}

extension TeamsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return players.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell", for: indexPath) as! TeamPlayerCell // using leaguePlayerCell is fine
            cell.reset()
            if indexPath.row < players.count {
                let player = players[indexPath.row]
                let team: Int? = playerTeam[player.id]
                cell.configure(player: player, team: team)
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SendCell", for: indexPath)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.section == 0 else { return false }
        let row = indexPath.row
        guard row < players.count else { return false }
        let player = players[row]
        
        return playerTeam[player.id] != nil
    }
}

extension TeamsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let row = indexPath.row
            guard row < players.count else { return }
            let player = players[row]
            
            if let team = playerTeam[player.id] {
                let newTeam = team + 1
                if newTeam > MAX_TEAMS {
                    playerTeam.removeValue(forKey: player.id)
                } else {
                    playerTeam[player.id] = newTeam
                }
            } else {
                playerTeam[player.id] = 1
            }
            
            tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
        } else {
            sendEmail()
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
        let row = indexPath.row
        guard row < players.count else { return }
        let player = players[row]
        
        playerTeam.removeValue(forKey: player.id)
        tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
        
        refreshRightNavButton()
    }
}

extension TeamsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true) {
            if let error = error as NSError? {
                self.simpleAlert("Could not send email", defaultMessage: "", error: error)
            } else if result == .sent {
                self.simpleAlert("Email sent", message: "Your team was sent successfully")
            } else if result == .failed {
                self.simpleAlert("Could not send email", message: "Mail composer had an issue")
            }
        }
    }
}
