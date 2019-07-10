//
//  EventPlayersViewController.swift
//  Balizinha_Example
//
//  Created by Ren, Bobby on 8/19/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha

class EventPlayersViewController: SearchableListViewController {
    var event: Balizinha.Event?

    @objc override var cellIdentifier: String {
        return "LeaguePlayerCell"
    }

    override var sections: [Section] {
        let string: String
        if event?.isPast ?? false {
            string = "Attended"
        } else {
            string = "Attending"
        }
        return [(string, eventPlayers), ("Other", otherPlayers)]
    }
    
    fileprivate var attendingPlayerIds: [String] = []

    // lists filtered based on search and membership
    fileprivate var eventPlayers: [Player] = []
    fileprivate var otherPlayers: [Player] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Players"
        
        load() { [weak self] in
            self?.loadEventPlayers() { [weak self] in
                self?.search(for: nil)
                self?.reloadTable()
            }
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Teams", style: .done, target: self, action: #selector(didClickTeams(_:)))
    }
    
    func loadEventPlayers(completion: (()->())?) {
        guard let event = event else {
            completion?()
            return
        }
        EventService.shared.observeUsers(for: event) {[weak self] (playerIds) in
            self?.attendingPlayerIds = playerIds
            completion?()
        }
    }
    
    @objc func didClickTeams(_ sender: Any) {
        guard !eventPlayers.isEmpty else {
            simpleAlert("Can't view teams", message: "No players are attending this event!")
            return
        }
        performSegue(withIdentifier: "toTeams", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "toTeams", let controller = segue.destination as? TeamsViewController else { return }
        controller.players = eventPlayers
        controller.event = event
    }
}

extension EventPlayersViewController { // UITableViewDataSource
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! LeaguePlayerCell // using leaguePlayerCell is fine
        cell.reset()
        let section = sections[indexPath.section]
        let array = section.objects
        if indexPath.row < array.count {
            let playerId = array[indexPath.row].id
            PlayerService.shared.withId(id: playerId) { [weak self] (player) in
                if let player = player {
                    DispatchQueue.main.async {
                        cell.configure(player: player, status: nil)
                    }
                }
            }
        }
        return cell
        
    }
}

extension EventPlayersViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let event = event else { return }
        
        // TODO: what happens when a player is clicked?
        // TODO: clicking allows the organizer to add or remove players?
        let section = sections[indexPath.section]
        guard indexPath.row < section.objects.count else { return }
        let playerId: String = section.objects[indexPath.row].id
        
        let message: String
        switch section.name {
        case "Attending", "Attended":
            message = "Remove player from event?"
        case "Other":
            message = "Add player to event?"
        default:
            message = "Clicking on this player will do nothing."
        }
        let alert = UIAlertController(title: "Toggle player?", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            self.togglePlayerAttendance(playerId: playerId, section: section, event: event)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func togglePlayerAttendance(playerId: String, section: Section, event: Event) {
        switch section.name {
        case "Attending", "Attended":
            EventService.shared.leaveEvent(event, userId: playerId, removedByOrganizer: true) { [weak self] (error) in
                if let error = error as NSError? {
                    self?.simpleAlert("Could not remove player", defaultMessage: "The player \(playerId) could not be removed from the event", error: error)
                } else {
                    self?.loadEventPlayers() {
                        self?.search(for: nil)
                        self?.reloadTable()
                    }
                }
            }
        case "Other":
            EventService.shared.joinEvent(event, userId: playerId, addedByOrganizer: true) { [weak self] (error) in
                if let error = error as NSError? {
                    self?.simpleAlert("Could not add player", defaultMessage: "The player \(playerId) could not be added to the event", error: error)
                } else {
                    self?.loadEventPlayers() {
                        self?.search(for: nil)
                        self?.reloadTable()
                    }
                }
            }
        default:
            return
        }
    }
}

// MARK: - Search
extension EventPlayersViewController {
    @objc override func updateSections(_ newObjects: [FirebaseBaseModel]) {
        // filter for event attendance
        eventPlayers = newObjects.filter { return attendingPlayerIds.contains($0.id) }.compactMap{$0 as? Player}
        otherPlayers = newObjects.filter { return !attendingPlayerIds.contains($0.id) }.compactMap{$0 as? Player}
    }
}
