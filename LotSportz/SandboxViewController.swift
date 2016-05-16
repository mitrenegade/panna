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
        service.listenForEvents(type: nil) { (results) in
            // completion function will get called once at the start, and each time events change
            for event: Event in results {
                // make sure events is unique and don't add duplicates
                let id = event.id()
                self.events[id] = event
            }
            self.tableView.reloadData()
        }
        
        // TODO: Create two listeners with an actual query filter and see if it works
    }

    // MARK: - Button actions
    @IBAction func didClickCreate() {
        service.createEvent(eventDict: nil)
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
        let sortedEvents = events.values.sort { (event1, event2) -> Bool in
            return event1.id() > event2.id()
        }
        let event = sortedEvents[indexPath.row]
        let type = event.type()
        let place = event.place()
        let time = event.timeString()
        cell.textLabel!.text = "\(type) at \(place)"
        cell.detailTextLabel?.text = time
        
        return cell
    }
}
