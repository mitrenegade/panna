//
//  JoinEventsTableViewController.swift
// Balizinha
//
//  Created by Tom Strissel on 5/23/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import SWRevealViewController

class JoinEventsTableViewController: UITableViewController, EventCellDelegate {

    var service = EventService.sharedInstance()
    var allEvents : [Event] = []
    var sortedEvents: [EventType: [Event]] = [.Soccer: [], .Basketball: [], .FlagFootball: []]
    let eventTypes = [EventType.Soccer, EventType.Basketball, EventType.FlagFootball]
    
    @IBOutlet var menuButton: UIBarButtonItem!
    
    override func viewWillAppear(_ animated: Bool) {
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
        }
        
        self.navigationItem.title = "Join Events"
        
        self.refreshEvents()
        self.listenFor(NotificationType.EventsChanged, action: #selector(JoinEventsTableViewController.refreshEvents), object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refreshEvents() {
        
        service.getEvents(type: nil) { (results) in
            // completion function will get called once at the start, and each time events change
            
            // 1: sort all events by time
            self.allEvents = results.sorted { (event1, event2) -> Bool in
                return event1.id > event2.id
            }
            
            // 2: Remove events the user has joined
            self.service.getEventsForUser(firAuth!.currentUser!, completion: { (eventIds) in
                
                print("eventsForUser \(firAuth!.currentUser!): \(eventIds)")

                for event in self.allEvents {
                    print("event id \(event.id) date \(event.dateString(event.endTime)) past \(event.isPast)")
                }
                print("all events count \(self.allEvents.count)")
                
                self.allEvents = self.allEvents.filter({ (event) -> Bool in
                    (!eventIds.contains(event.id) && !event.isPast)
                })
                
                // 3: Organize events by type
                self.sortedEvents = [.Soccer: [], .Basketball: [], .FlagFootball: []]
                
                for event in self.allEvents{
                    var oldValue = self.sortedEvents[event.type]
                    print(event.type)
                    oldValue?.append(event)
                    self.sortedEvents.updateValue(oldValue!, forKey: event.type)
                }
                self.tableView.reloadData()
            })
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sortedEvents.keys.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            let soccerEvents = self.sortedEvents[.Soccer]
            return (soccerEvents?.count)!
        case 1:
            let basketballEvents = self.sortedEvents[.Basketball]
            return (basketballEvents?.count)!
        default:
            let flagFootballEvents = self.sortedEvents[.FlagFootball]
            return (flagFootballEvents?.count)!
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return eventTypes[section].rawValue
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : EventCell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventCell
        cell.delegate = self
        
        let event = sortedEvents[eventTypes[indexPath.section]]![indexPath.row]
        cell.setupWithEvent(event)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        let list = sortedEvents[eventTypes[section]]
        return list!.count == 0 ? 0 : UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "toEventDetails", sender: self)
    }
    
    // MARK: EventCellDelegate
    func joinOrLeaveEvent(_ event: Event, join: Bool) {
        let user = firAuth!.currentUser!
        if join {
            //add notification in case user doesn't return to MyEvents
            self.service.joinEvent(event, user: user)
            NotificationService.scheduleNotificationForEvent(event)
        }
        else {
            self.service.leaveEvent(event, user: user)
        }
 
        self.refreshEvents()
    }
    
    
     // MARK: - Navigation     
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let detailsController = segue.destination as! EventDisplayViewController
        detailsController.alreadyJoined = false
        detailsController.delegate = self
        
        let indexPath = self.tableView.indexPathForSelectedRow
        detailsController.event = sortedEvents[eventTypes[indexPath!.section]]![indexPath!.row]
        
     // Pass the selected object to the new view controller.
     }
    

}
