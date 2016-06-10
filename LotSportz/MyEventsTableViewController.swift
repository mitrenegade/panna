//
//  MyEventsTableViewController.swift
//  LotSportz
//
//  Created by Tom Strissel on 5/18/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import SWRevealViewController

class MyEventsTableViewController: UITableViewController, EventCellDelegate {
    
    var service = EventService.sharedInstance()
    var sortedEvents: [Event] = []
    @IBOutlet var menuButton: UIBarButtonItem!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
        }
        
        self.refreshEvents()
        
        self.navigationItem.title = "My Events"
        //print(sortedEvents)
        //print(events)

        self.service.listenForEventUsers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func refreshEvents() {
        
        service.getEvents(type: nil) { (results) in
            // completion function will get called once at the start, and each time events change
            
            // 1: sort all events by time
            self.sortedEvents = results.sort { (event1, event2) -> Bool in
                return event1.id() > event2.id()
            }
            
            // 2: Remove events the user has joined
            self.service.getEventsForUser(firAuth!.currentUser!, completion: { (eventIds) in
                let filteredList = self.sortedEvents.filter({ (event) -> Bool in
                    eventIds.contains(event.id())
                })
                self.sortedEvents = filteredList
                
                self.tableView.reloadData()
            })
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return self.sortedEvents.count
        case 1:
            return 0
        default:
            break
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Upcoming events"
        case 1:
            return "Past events"
        default:
            break
        }
        
        return nil
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell : EventCell = tableView.dequeueReusableCellWithIdentifier("EventCell", forIndexPath: indexPath) as! EventCell
        cell.delegate = self
        let event = self.sortedEvents[indexPath.row]
        cell.setupWithEvent(event)
        return cell
    }

    // MARK: EventCellDelegate
    func joinOrLeaveEvent(event: Event, join: Bool) {
        let user = firAuth!.currentUser!
        if join {
            self.service.joinEvent(event, user: user)
        }
        else {
            self.service.leaveEvent(event, user: user)
        }
        
        self.refreshEvents()
    }
}
