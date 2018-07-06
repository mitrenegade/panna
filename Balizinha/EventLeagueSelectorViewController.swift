//
//  EventLeagueSelectorViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 7/1/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class EventLeagueSelectorViewController: UIViewController {
    @IBOutlet weak fileprivate var tableView: UITableView!
    var playerLeagues: [League] = []
    var loading: Bool = true
    
    weak var delegate: CreateEventDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Select League"

        // Do any additional setup after loading the view.
        loadData()

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(didClickCancel(_:)))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "League", style: .done, target: self, action: #selector(didClickBack(_:)))
    }

    fileprivate func loadData() {
        guard let player = PlayerService.shared.current.value as? Player else {
            loading = false
            return
        }
        
        loading = true
        playerLeagues.removeAll()

        LeagueService.shared.leagues(for: player) { [weak self] (playerLeagueIds) in
            guard let ids = playerLeagueIds else {
                self?.loading = false
                return
            }
            
            var organizerCount = 0
            for (leagueId, membership) in ids {
                guard membership.isOrganizer else { continue }
                organizerCount += 1
                LeagueService.shared.withId(id: leagueId, completion: { [weak self] (league) in
                    if let league = league {
                        self?.playerLeagues.append(league)
                        DispatchQueue.main.async {
                            self?.reloadTableData()
                        }
                    }
                })
            }
            if organizerCount == 0 {
                DispatchQueue.main.async {
                    self?.loading = false
                    self?.reloadTableData()
                    self?.simpleAlert("You're not an organizer", message: "You currently can't organize games for any leagues. Please contact the league owners to become an organizer.")
                }
                return
            }
        }
    }
    
    func reloadTableData() {
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "toCreateEvent", let controller = segue.destination as? CreateEventViewController else { return }
        guard let league = sender as? League else { return }
        controller.league = league
        controller.delegate = delegate
    }
    
    @IBAction func didClickCancel(_ sender: AnyObject?) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didClickBack(_ sender: AnyObject?) {
        navigationController?.popToRootViewController(animated: true)
    }
}

extension EventLeagueSelectorViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if playerLeagues.isEmpty {
            return 1
        }
        return playerLeagues.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !playerLeagues.isEmpty, indexPath.row < playerLeagues.count else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "info", for: indexPath)
            cell.textLabel?.text = loading ? "Loading your leagues..." : "No leagues found"
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "LeagueCell") as! LeagueCell
        cell.configure(league: playerLeagues[indexPath.row])
        return cell
    }
}

extension EventLeagueSelectorViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !playerLeagues.isEmpty, indexPath.row < playerLeagues.count else {
            return
        }
        let league = playerLeagues[indexPath.row]
        performSegue(withIdentifier: "toCreateEvent", sender: league)
    }
}
