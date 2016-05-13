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
    var events: [AnyObject]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    // MARK: - Button actions
    @IBAction func didClickCreate() {
        service.createEvent(eventDict: nil)
    }
    
    @IBAction func didClickRefresh() {
        service.getEvents(type: nil)
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if events != nil {
            return events!.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("EventCell", forIndexPath: indexPath)
        return cell
    }
}
