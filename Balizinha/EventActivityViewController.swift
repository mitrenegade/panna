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
                ActionService().listenForActions(event: newVal, completion: handleActionUpdates)
            }
        }
    }
    weak var delegate: EventDisplayComponentDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    var handleActionUpdates: actionUpdateHandler = { results in
        print("results: \(results)")
    }
}
