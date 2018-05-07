//
//  LeaguesViewController.swift
//  Balizinha
//
//  Created by Ren, Bobby on 4/30/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class LeaguesViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var playerLeagues: [League] = []
    var otherLeagues: [League] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let profileButton = UIBarButtonItem(image: UIImage(named: "menu"), style: .done, target: self, action: #selector(didClickProfile(_:)))
        navigationItem.leftBarButtonItem = profileButton
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80

        loadData()
    }
    
    @objc fileprivate func didClickProfile(_ sender: Any) {
        print("Go to Account")
        guard let controller = UIStoryboard(name: "Account", bundle: nil).instantiateViewController(withIdentifier: "AccountViewController") as? AccountViewController else { return }
        let nav = UINavigationController(rootViewController: controller)
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "iconClose30"), style: .plain, target: self, action: #selector(self.dismissProfile))
        present(nav, animated: true) {
        }
    }
    
    @objc fileprivate func dismissProfile() {
        dismiss(animated: true, completion: nil)
    }
    
    fileprivate func loadData() {
        guard let player = PlayerService.shared.current.value as? Player else { return }
        
        otherLeagues.removeAll()
        playerLeagues.removeAll()
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        var leagueIds: [String] = []
        LeagueService.shared.leagues(for: player) { (playerLeagueIds) in
            if let ids = playerLeagueIds {
                leagueIds.append(contentsOf: ids)
            }
            dispatchGroup.leave()
            print("User leagues received: \(leagueIds)")
        }
        
        dispatchGroup.enter()
        LeagueService.shared.getLeagues { [weak self] (leagues) in
            self?.otherLeagues.append(contentsOf: leagues)
            dispatchGroup.leave()
            print("All leagues received: \(leagues.count)")
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
            guard let weakself = self else { return }
            weakself.playerLeagues = weakself.otherLeagues.filter() {
                return leagueIds.contains($0.id)
            }
            weakself.otherLeagues = weakself.otherLeagues.filter() {
                return !leagueIds.contains($0.id)
            }
            
            DispatchQueue.main.async {
                weakself.reloadTableData()
            }
        }
    }
    
    fileprivate func joinOrLeave(_ league: League) {
        if LeagueService.shared.playerIsIn(league: league) {
            // leave league
            print("You cannot leave league! muhahaha")
        } else {
            // join league
            LeagueService.shared.join(league: league) { [weak self] (result, error) in
                print("Join league result \(result) error \(error)")
                self?.loadData()
            }
        }
    }
}

extension LeaguesViewController: UITableViewDataSource {
    fileprivate func reloadTableData() {
        tableView.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return playerLeagues.count
        } else if section == 1 {
            return otherLeagues.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : LeagueCell = tableView.dequeueReusableCell(withIdentifier: "LeagueCell", for: indexPath) as! LeagueCell
        let row = indexPath.row
        let section = indexPath.section
        if section == 0 {
            let league = playerLeagues[row]
            cell.configure(league: league)
        } else if section == 1 {
            let league = otherLeagues[row]
            cell.configure(league: league)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && playerLeagues.isEmpty {
            return 0
        }
        if section == 1 && otherLeagues.isEmpty {
            return 0
        }
        
        return 40
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return playerLeagues.isEmpty ? nil : "Your leagues"
        }
        if section == 1 {
            return otherLeagues.isEmpty ? nil : "Other leagues"
        }
        return nil
    }
}

extension LeaguesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        var message: String?
        var league: League?
        if indexPath.section == 0 {
            guard indexPath.row < playerLeagues.count else { return }
            league = playerLeagues[indexPath.row]
            message = "Do you want to leave \(league?.name ?? " this league")?"
        } else if indexPath.section == 1 {
            guard indexPath.row < otherLeagues.count else { return }
            league = otherLeagues[indexPath.row]
            message = "Do you want to join \(league?.name ?? " this league")?"
        }
        
        guard let selectedLeague = league else { return }
        let alert = UIAlertController(title: "Are you sure?", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            self.joinOrLeave(selectedLeague)
        }))
        present(alert, animated: true, completion: nil)
    }
}
