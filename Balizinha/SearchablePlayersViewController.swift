//
//  EventPlayersViewController.swift
//  Balizinha_Example
//
//  Created by Ren, Bobby on 8/17/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import FirebaseCore
import Balizinha
import FirebaseDatabase

class SearchablePlayersViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var constraintBottomOffset: NSLayoutConstraint!

    // search/filter
    var searchTerm: String?
    @IBOutlet weak var containerSearch: UIView!
    @IBOutlet weak var inputSearch: UITextField!
    @IBOutlet weak var buttonSearch: UIButton!

    // only needed for certain subclasses
    //    var league: League?
    
    // specific to each subclass
    typealias Section = (name: String, players: [Player])
    fileprivate var players: [Player] = []
    var sections: [Section] {
        return [("All", players)]
    }
    
    var allPlayers: [Player] = []
    var memberships: [String: Membership.Status] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func reloadTableData() {
        tableView.reloadData()
    }

    func loadFromRef(completion: (()->())?) { // loads all players, using observed player endpoint
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
                completion?()
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

extension SearchablePlayersViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < sections.count else { return 0 }
        let sectionStruct = sections[section]
        let players = sectionStruct.players
        return players.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section < sections.count else { return nil }
        let sectionStruct = sections[section]
        return sectionStruct.name
    }
    
    @objc var cellIdentifier: String {
        return "PlayerCell"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        assertionFailure("Must implement cellForRow")
        return UITableViewCell()
    }
}

// MARK: - Search
extension SearchablePlayersViewController {
    @IBAction func didClickSearch(_ sender: Any?) {
        search(for: inputSearch.text)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        didClickSearch(nil)
        return true
    }
    
    func search(for string: String?) {
        print("Search for string \(String(describing: string))")
        
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
        
        updateSections(filteredPlayers)
        reloadTableData()
    }
    
    @objc func updateSections(_ players: [Player]) {
        // no op unless the controller needs to have sections
        self.players = players
        return
    }
}
