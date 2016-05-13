//
//  SandboxViewController.swift
//  LotSportz
//
//  Created by Bobby Ren on 5/12/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class SandboxViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var service = EventService.sharedInstance()
    var events: [NSObject: Event] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    // MARK: - Button actions
    @IBAction func didClickCreate() {
        service.createEvent(eventDict: nil)
    }
    
    @IBAction func didClickRefresh() {
        service.getEvents(type: nil) { (result) in
            if let event: Event = result {
                let id = event.id()
                self.events[id] = event
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("EventCell", forIndexPath: indexPath)
        return cell
    }
}
