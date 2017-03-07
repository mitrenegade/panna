//
//  EventActionsViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/5/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

class EventActionsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!

    var event: Event? {
        didSet {
            if let newVal = event {
                ActionService().observeActions(forEvent: newVal, completion: { (action) -> (Void) in
                    self.actions[action.id] = action
                    self.reloadData()
                })
            }
        }
    }
    var actions: [String: Action] = [:]
    var sortedActions: [Action]?
    weak var delegate: EventDisplayComponentDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    func reloadData() {
        self.sortedActions = actions.values.filter({ (action) -> Bool in
            return action.createdAt != nil
        }).sorted(by: { (a, b) -> Bool in
            a.createdAt! < b.createdAt!
        })
        self.tableView.reloadData()
    }
}

extension EventActionsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let actions = self.sortedActions else { return 1 }
        return actions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell", for: indexPath)
        guard let actions = self.sortedActions, indexPath.row < actions.count else {
            cell.textLabel?.text = "No recent activity"
            return cell
        }
        let action = actions[indexPath.row]
        cell.textLabel?.text = action.displayString
        return cell
    }
}
