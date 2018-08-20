//
//  EventActivityViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/5/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class EventActivityViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var firstAppear: Bool = true
    
    var event: Balizinha.Event? {
        didSet {
            if let newVal = event {
                ActionService().observeActions(forEvent: newVal, completion: { action in
                    // visible should always be true - if an action is deleted, the eventAction should be deleted
                    if action.visible {
                        self.actions[action.id] = action
                        self.reloadData()
                    }
                    else {
                        self.actions[action.id] = nil
                    }
                })
            }
        }
    }
    var actions: [String: Action] = [:]
    var sortedActions: [Action]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 120
        
        self.tableView.layer.borderWidth = 2
        self.tableView.layer.cornerRadius = 20
        self.tableView.layer.borderColor = UIColor.darkGray.cgColor
    }
    
    func reloadData() {
        self.sortedActions = actions.values.sorted(by: { (a, b) -> Bool in
            if a.createdAt == nil && b.createdAt != nil {
                return false
            }
            else if b.createdAt == nil && a.createdAt != nil {
                return true
            }
            else if a.createdAt == nil && b.createdAt == nil {
                return true
            }
            return a.createdAt! < b.createdAt!
        })
        self.tableView.reloadData()
        if let actions = self.sortedActions, actions.count > 0 {
            firstAppear = false
            self.tableView.scrollToRow(at: NSIndexPath(row: actions.count - 1, section: 0) as IndexPath, at: .top, animated: true)
        }
    }
}

extension EventActivityViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let actions = self.sortedActions else { return 1 }
        return actions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let actions = self.sortedActions, indexPath.row < actions.count else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell", for: indexPath)
            cell.textLabel?.text = "No recent activity"
            return cell
        }
        
        let action = actions[indexPath.row]
        let viewModel = ActionViewModel(action: action)
        let cellIdentifier = viewModel.userPerformedAction ? "ActionCellUser": "ActionCellOthers"
        
        // make sure action has a name
        if action.username == nil, let userId = action.userId {
            // lazily request for next time
            PlayerService.shared.withId(id: userId, completion: { player in
                if let name = player?.name {
                    action.username = name
                }
            })
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ActionCell
        cell.configureWith(action: action)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let actions = self.sortedActions, indexPath.row < actions.count else {
            return false
        }
        let action = actions[indexPath.row]
        let viewModel = ActionViewModel(action: action)
        return action.type == .chat && viewModel.userPerformedAction
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard let actions = self.sortedActions, indexPath.row < actions.count else {
            return
        }
        let action = actions[indexPath.row]
        
        if editingStyle == .delete {
            ActionService.delete(action: action)
        }
    }
}
