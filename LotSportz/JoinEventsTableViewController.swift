//
//  JoinEventsTableViewController.swift
//  LotSportz
//
//  Created by Tom Strissel on 5/23/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import SWRevealViewController

class JoinEventsTableViewController: UITableViewController, EventCellDelegate {

    var service = EventService.sharedInstance()
    var allEvents : [Event] = []
    var sortedEvents: [String: [Event]] = ["Soccer": [], "Basketball": [], "Flag Football": []]
    let eventTypes = ["Soccer", "Basketball", "Flag Football"]
    
    @IBOutlet var menuButton: UIBarButtonItem!
    
    override func viewWillAppear(animated: Bool) {
        self.refreshEvents()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
        }
        
        self.navigationItem.title = "Join Events"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refreshEvents() {
        
        service.getEvents(type: nil) { (results) in
            // completion function will get called once at the start, and each time events change
            
            // 1: sort all events by time
            self.allEvents = results.sort { (event1, event2) -> Bool in
                return event1.id() > event2.id()
            }
            
            // 2: Remove events the user has joined
            self.service.getEventsForUser(firAuth!.currentUser!, completion: { (eventIds) in
                self.allEvents = self.allEvents.filter({ (event) -> Bool in
                    (!eventIds.contains(event.id()) && !event.isPast())
                })
                
                // 3: Organize events by type
                self.sortedEvents = ["Soccer": [], "Basketball": [], "Flag Football": []]
                
                for event in self.allEvents{
                    var oldValue = self.sortedEvents[event.type()]
                    print(event.type())
                    oldValue?.append(event)
                    self.sortedEvents.updateValue(oldValue!, forKey: event.type())
                }
                self.tableView.reloadData()
            })
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.sortedEvents.keys.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            let soccerEvents = self.sortedEvents["Soccer"]
            return (soccerEvents?.count)!
        case 1:
            let basketballEvents = self.sortedEvents["Basketball"]
            return (basketballEvents?.count)!
        default:
            let flagFootballEvents = self.sortedEvents["Flag Football"]
            return (flagFootballEvents?.count)!
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return eventTypes[section]
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell : EventCell = tableView.dequeueReusableCellWithIdentifier("EventCell", forIndexPath: indexPath) as! EventCell
        cell.delegate = self
        
        let event = sortedEvents[eventTypes[indexPath.section]]![indexPath.row]
        cell.setupWithEvent(event)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        let list = sortedEvents[eventTypes[section]]
        return list!.count == 0 ? 0 : UITableViewAutomaticDimension
    }
    
    // MARK: EventCellDelegate
    func joinOrLeaveEvent(event: Event, join: Bool) {
        let user = firAuth!.currentUser!
        if join {
            //add notification in case user doesn't return to MyEvents
            self.service.joinEvent(event, user: user)
            let notification = UILocalNotification()
            notification.fireDate = NSDate(year: event.startTime().year(), month: event.startTime().month(), day: event.startTime().day(), hour: event.startTime().hour() - 1, minute: event.startTime().minute(), second: event.startTime().second())
            notification.alertBody = "You have an event in 1 hour!"
            UIApplication.sharedApplication().scheduleLocalNotification(notification)

        }
        else {
            self.service.leaveEvent(event, user: user)
        }
 
        self.refreshEvents()
    }

}
