//
//  MyEventsTableViewController.swift
//  LotSportz
//
//  Created by Tom Strissel on 5/18/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import SWRevealViewController
import Parse

class MyEventsTableViewController: UITableViewController, EventCellDelegate {
    
    var service = EventService.sharedInstance()
    var sortedUpcomingEvents: [Event] = []
    var sortedPastEvents: [Event] = []
    @IBOutlet var menuButton: UIBarButtonItem!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
        }
        
        self.refreshEvents()
        
        
        self.navigationItem.title = "My Events"
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
            self.sortedUpcomingEvents = results.sort { (event1, event2) -> Bool in
                return event1.id() < event2.id()
            }
            
            // 2: Remove events the user has joined
            self.service.getEventsForUser(firAuth!.currentUser!, completion: { (eventIds) in
                self.sortedUpcomingEvents = self.sortedUpcomingEvents.filter({ (event) -> Bool in
                    eventIds.contains(event.id())
                })
                
                let original = self.sortedUpcomingEvents
                self.sortedPastEvents = original.filter({ (event) -> Bool in
                    event.isPast()
                })
                
                self.sortedUpcomingEvents = original.filter({ (event) -> Bool in
                    !event.isPast()
                })
                NotificationService.refreshNotifications(self.sortedUpcomingEvents)
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
            return self.sortedUpcomingEvents.count
        case 1:
            return self.sortedPastEvents.count
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
        
        switch indexPath.section {
        case 0:
            let event = self.sortedUpcomingEvents[indexPath.row]
            cell.setupWithEvent(event)
        default:
            let event = self.sortedPastEvents[indexPath.row]
            cell.setupWithEvent(event)
        }
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
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard indexPath.section == 0 else {
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            return
        }

        //self.performSegueWithIdentifier("toMyEventDetails", sender: self)

        // TEST: push
        let params = ["channel": "eventsGlobal", "message": "test message"]
        PFCloud.callFunctionInBackground("sendPushFromDevice", withParameters: params) { (results, error) in
            print("results \(results) error \(error)")
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let detailsController = segue.destinationViewController as! EventDisplayViewController
        detailsController.alreadyJoined = true
        detailsController.delegate = self
        
        let indexPath = self.tableView.indexPathForSelectedRow
        detailsController.event = sortedUpcomingEvents[indexPath!.row]
        
    }
    
}
