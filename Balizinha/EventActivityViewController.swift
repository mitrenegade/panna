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
                ActionService().listenForActions(event: newVal, controller: self, completion: handleActionUpdates)
            }
        }
    }
    var actions: [Action]?
    
    weak var delegate: EventDisplayComponentDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    var handleActionUpdates: actionUpdateHandler = { results, controller in        
        controller.actions = results
        controller.tableView.reloadData()
    }
}

extension EventActionsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let actions = self.actions else { return 0 }
        return actions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell", for: indexPath)
        guard let actions = self.actions, indexPath.row < actions.count else {
            return cell
        }
        let action = actions[indexPath.row]
        cell.textLabel?.text = action.displayString
        return cell
    }
}
