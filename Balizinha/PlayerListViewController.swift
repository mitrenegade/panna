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
    var players: [(player: Player, expanded: Bool)] = []
    var profileImageUrl: [String: String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.title = "Players"
    }
    
    override func load() {
        let playerRef = firRef.child("players").queryOrdered(byChild: "createdAt")
        playerRef.observe(.value) {[weak self] (snapshot) in
            guard snapshot.exists() else { return }
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                self?.players.removeAll()
                for playerDict: DataSnapshot in allObjects {
                    let player = Player(snapshot: playerDict)
                    FirebaseImageService().profileUrl(with: player.id) {[weak self] (url) in
                        if let urlString = url?.absoluteString {
                            self?.profileImageUrl[player.id] = urlString
                        }
                    }
                    self?.players.append((player, false))
                }
                self?.players.sort(by: { (p1, p2) -> Bool in
                    guard let t1 = p1.player.createdAt else { return false }
                    guard let t2 = p2.player.createdAt else { return true}
                    return t1 > t2
                })
                self?.reloadTable()
            }
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
            let tuple = players[indexPath.row]
            let player = tuple.player
            let expanded = tuple.expanded
            cell.configure(player: player, expanded: expanded)
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
        
        var tuple = players[indexPath.row]
        tuple.expanded = !tuple.expanded
        players[indexPath.row] = tuple
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
