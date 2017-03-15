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
    var firstAppear: Bool = true
    
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
        //self.delegate?.componentHeightChanged(controller: self, newHeight: self.tableView.contentSize.height)
        
        if let actions = self.sortedActions, actions.count > 0 {
            firstAppear = false
            self.tableView.scrollToRow(at: NSIndexPath(row: actions.count - 1, section: 0) as IndexPath, at: .bottom, animated: true)
        }
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
        guard let actions = self.sortedActions, indexPath.row < actions.count else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell", for: indexPath)
            cell.textLabel?.text = "No recent activity"
            return cell
        }
        
        let action = actions[indexPath.row]
        let cellIdentifier = action.userIsOwner ? "ActionCellUser": "ActionCellOthers"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ActionCell
        cell.configureWith(action: action)
        return cell
    }
}
