//
//  LeagueViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 6/24/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class LeagueViewController: UIViewController {
    fileprivate enum Row { // TODO: make CaseIterable
        case title
        case tags
        case info
        case players
    }
    
    fileprivate var rows: [Row] = [.title, .tags, .info, .players]
    
    @IBOutlet weak var tableView: UITableView!
    var tagView: ResizableTagView?
    
    var league: League?
    var players: [Player] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
        
        observePlayers()
    }
    
    func observePlayers() {
        guard let league = self.league else { return }
        players.removeAll()
        let dispatchGroup = DispatchGroup()
        LeagueService.shared.players(for: league) { (playerIds) in
            for playerId in playerIds ?? [] {
                dispatchGroup.enter()
                PlayerService.shared.withId(id: playerId, completion: {[weak self] (player) in
                    if let player = player {
                        self?.players.append(player)
                        dispatchGroup.leave()
                    }
                })
            }
            dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
                if let index = self?.rows.index(of: .players) {
                    DispatchQueue.main.async {
                        self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    }
                }
            }
        }
    }
}

extension LeagueViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch rows[indexPath.row] {
        case .title:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeagueTitleCell", for: indexPath) as! LeagueTitleCell
            cell.configure(league: league)
            return cell
        case .tags:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeagueTagsCell", for: indexPath) as! LeagueTagsCell
            cell.configure(league: league)
            return cell
        case .info:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeagueInfoCell", for: indexPath) as! LeagueInfoCell
            cell.configure(league: league)
            return cell
        case .players:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeaguePlayersCell", for: indexPath) as! LeaguePlayersCell
            cell.configure(players: players)
            return cell
        }
    }
}

extension LeagueViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
