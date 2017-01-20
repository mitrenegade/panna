//
//  MyEventsTableViewController.swift
// Balizinha
//
//  Created by Tom Strissel on 5/18/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import SWRevealViewController
import Parse

class MyEventsTableViewController: UITableViewController, EventCellDelegate {
    
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
        self.listenFor(NotificationType.EventsChanged, action: #selector(MyEventsTableViewController.refreshEvents), object: nil)
        
        self.navigationItem.title = "My Events"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func refreshEvents() {
        
        EventService.sharedInstance().getEvents(type: nil) { (results) in
            // completion function will get called once at the start, and each time events change
            
            // 1: sort all events by time
            self.sortedUpcomingEvents = results.sorted { (event1, event2) -> Bool in
                return event1.id < event2.id
            }
            
            // 2: Remove events the user has joined
            EventService.sharedInstance().getEventsForUser(firAuth!.currentUser!, completion: { (eventIds) in
                self.sortedUpcomingEvents = self.sortedUpcomingEvents.filter({ (event) -> Bool in
                    eventIds.contains(event.id)
                })
                
                let original = self.sortedUpcomingEvents
                self.sortedPastEvents = original.filter({ (event) -> Bool in
                    event.isPast
                })
                
                self.sortedUpcomingEvents = original.filter({ (event) -> Bool in
                    !event.isPast
                })
                NotificationService.refreshNotifications(self.sortedUpcomingEvents)
                self.tableView.reloadData()
            })
        }
        
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
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

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : EventCell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventCell
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
    func joinOrLeaveEvent(_ event: Event, join: Bool) {
        let user = firAuth!.currentUser!
        if join {
            EventService.sharedInstance().joinEvent(event, user: user)
        }
        else {
            EventService.sharedInstance().leaveEvent(event, user: user)
        }
        
        self.refreshEvents()
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else {
            self.tableView.deselectRow(at: indexPath, animated: true)
            return
        }

        self.performSegue(withIdentifier: "toMyEventDetails", sender: self)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let detailsController = segue.destination as! EventDisplayViewController
        detailsController.alreadyJoined = true
        detailsController.delegate = self
        
        let indexPath = self.tableView.indexPathForSelectedRow
        detailsController.event = sortedUpcomingEvents[indexPath!.row]
        
    }
    
}
