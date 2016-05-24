//
//  JoinEventsTableViewController.swift
//  LotSportz
//
//  Created by Tom Strissel on 5/23/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import SWRevealViewController

class JoinEventsTableViewController: UITableViewController {

    var service = EventService.sharedInstance()
    var events: [NSObject: Event] = [:]
    var sortedEvents: [Event] = []
    
    @IBOutlet var menuButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
        }
        
        service.listenForEvents(type: nil) { (results) in
            // completion function will get called once at the start, and each time events change
            for event: Event in results {
                print("Found an event")
                // make sure events is unique and don't add duplicates
                let id = event.id()
                self.events[id] = event
            }
            // Configure the cell...
            self.sortedEvents = self.events.values.sort { (event1, event2) -> Bool in
                return event1.id() > event2.id()
            }
            
            self.tableView.reloadData()
            
        }
        
        self.navigationItem.title = "Join Events"
        //print(sortedEvents)
        //print(events)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return events.count
        case 1:
            return 0
        default:
            break
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section { //To-Do: Organize events by type
        case 0:
            return "Soccer"
        case 1:
            return "Basketball"
        default:
            break
        }
        
        return nil
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell : EventCell = tableView.dequeueReusableCellWithIdentifier("EventCell", forIndexPath: indexPath) as! EventCell
        
        
        let event = sortedEvents[indexPath.row]
        let place = event.place()
        //let time = event.timeString()
        cell.labelLocation.text = place
        cell.labelDate.text = "Thurs May 5" //To-Do: Sanitize Date info from event.time
        cell.labelTime.text = "12pm - 3pm" //To-Do: Add start/end time attributes for events
        cell.labelFull.text = "You're going!" //To-Do: Add functionality whether or not event is full
        
        cell.labelAttendance.text = "10 Attending" //To-Do: "\(event.maxPlayers()) Attending"
        cell.btnAction.tag = indexPath.row //tag uniquely identifies cell, and therefore, the event
        
        switch event.type() {
        case "Basketball":
            cell.eventLogo.image = UIImage(named: "backetball")
        case "Soccer":
            cell.eventLogo.image = UIImage(named: "soccer")
        case "Flag Football":
            cell.eventLogo.image = UIImage(named: "football")
        default:
            cell.eventLogo.hidden = true
        }
        switch indexPath.section {
        case 0:
            cell.btnAction.hidden = false
        case 1:
            cell.btnAction.hidden = true
        default:
            break
            
        }
        
        return cell
    }
    
    /*
     override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
     let event = sortedEvents[indexPath.row]
     
     //To-Do: Don't think we need this, as long as we can read in taps from join/cancel buttons
     }
     */
     
    
}
