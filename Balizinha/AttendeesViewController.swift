//
//  AttendeesViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 4/8/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//
// not actually used yet but can be used to edit attendances

import UIKit
import FirebaseCommunity
import RxSwift
import Balizinha

class AttendeesViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var disposeBag: DisposeBag = DisposeBag()
    var event: Balizinha.Event? {
        didSet {
            if oldValue != event {
                load()
            }
        }
    }
    var players: [String: (player: Player, expanded: Bool)] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        load()
    }

    fileprivate func load() {
        if let event = event {
            EventService.shared.usersObserver(for: event).subscribe(onNext: { userIds in
                print("userIds \(userIds.count)")
                for userId in userIds {
                    PlayerService.shared.withId(id: userId, completion: { [weak self] (player) in
                        if let player = player {
                            self?.players[userId] = (player: player, expanded: false)
                            // TODO: sort by join date
                            self?.tableView.reloadData()
                        }
                    })
                }
            }).disposed(by: disposeBag)
        } else {
            disposeBag = DisposeBag()
        }
    }
}

extension AttendeesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return players.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell", for: indexPath) as! PlayerCell
        let tuples = Array(players.values.enumerated())
        if indexPath.row < tuples.count {
            let tuple = tuples[indexPath.row].element
            let player = tuple.player
            let expanded = tuple.expanded
            cell.configure(player: player, expanded: expanded)
        } else {
            cell.reset()
        }
        return cell
    }
}

extension AttendeesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard indexPath.row < players.count else { return }
        
//        let tuples = Array(players.values.enumerated())
//        var tuple = tuples[indexPath.row].element
//        tuple.expanded = !tuple.expanded
//        players[indexPath.row] = tuple
//        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
