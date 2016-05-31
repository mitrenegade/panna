//
//  MyEventsTableViewController.swift
//  LotSportz
//
//  Created by Tom Strissel on 5/18/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import SWRevealViewController

class MyEventsTableViewController: UITableViewController {
    
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

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func refreshEvents() {
        service.getEvents(type: nil) { (results) in
            // completion function will get called once at the start, and each time events change
            var events: [NSObject: Event] = [:]
            for event: Event in results {
                print("Found an event")
                // make sure events is unique and don't add duplicates
                let id = event.id()
                events[id] = event
            }
            // Configure the cell...
            self.sortedEvents = events.values.sort { (event1, event2) -> Bool in
                return event1.id() > event2.id()
            }
            var participatingEvents: [Event] = []
            self.service.getEventsForUser(firAuth!.currentUser!, completion: { (eventIds) in
                print("done")
                for event: Event in self.sortedEvents {
                    if eventIds.contains(event.id()) {
                        print("event exists: \(event.id())")
                        participatingEvents.append(event)
                    }
                    else {
                        print("not in")
                    }
                }
                self.sortedEvents = participatingEvents
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
 
        
        let event = self.sortedEvents[indexPath.row]
        let place = event.place()
        //let time = event.timeString()
        cell.labelLocation.text = place
        cell.labelDate.text = "Thurs May 5" //To-Do: Sanitize Date info from event.time
        cell.labelTime.text = "12pm - 3pm" //To-Do: Add start/end time attributes for events
        cell.labelFull.text = "Event full" //To-Do: Add functionality whether or not event is full
        
        cell.labelAttendance.text = "10 Attending" //To-Do: "\(event.maxPlayers()) Attending"
        cell.btnAction.tag = indexPath.row
        
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
        
    }
    
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
