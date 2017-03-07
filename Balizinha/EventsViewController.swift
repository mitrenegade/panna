//
//  EventsViewController.swift
// Balizinha
//
//  Created by Tom Strissel on 5/23/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class EventsViewController: UITableViewController {

    var service = EventService.shared
    var allEvents : [Event] = []
    var sortedEvents: [EventType: [Event]] = [.balizinha: [], .basketball: [], .flagFootball: []]
    let eventTypes = [EventType.balizinha, EventType.basketball, EventType.flagFootball]
    
    override func viewWillAppear(_ animated: Bool) {
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Events"
        
        let addButton = UIButton(type: .custom)
        addButton.setImage(UIImage.init(named: "plusIcon30"), for: .normal)
        addButton.addTarget(self, action: #selector(self.didClickAddEvent(sender:)), for: .touchUpInside)
        addButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addButton)
        
        self.refreshEvents()
        self.listenFor(NotificationType.EventsChanged, action: #selector(self.refreshEvents), object: nil)
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
                    print("event id \(event.id) date \(event.dateString(event.endTime ?? Date())) past \(event.isPast)")
                }
                print("all events count \(self.allEvents.count)")
                
                self.allEvents = self.allEvents.filter({ (event) -> Bool in
                    (!eventIds.contains(event.id) && !event.isPast)
                })
                
                // 3: Organize events by type
                self.sortedEvents = [.balizinha: [], .basketball: [], .flagFootball: []]
                
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
    
    func didClickAddEvent(sender: Any) {
        self.simpleAlert("Create an event?", message: "You must be a paid organizer to create a new game. Click to proceed.") {
            // create
            self.performSegue(withIdentifier: "toCreateEvent", sender: nil)
        }
    }
}

extension EventsViewController {
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sortedEvents.keys.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            let soccerEvents = self.sortedEvents[.balizinha]
            return (soccerEvents?.count)!
        case 1:
            let basketballEvents = self.sortedEvents[.basketball]
            return (basketballEvents?.count)!
        default:
            let flagFootballEvents = self.sortedEvents[.flagFootball]
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
        tableView.deselectRow(at: indexPath, animated: true)
        let event = sortedEvents[eventTypes[indexPath.section]]![indexPath.row]
        performSegue(withIdentifier: "toEventDetails", sender: event)
    }
}

extension EventsViewController: EventCellDelegate {
    // MARK: EventCellDelegate
    func joinOrLeaveEvent(_ event: Event, join: Bool) {
        if join {
            //add notification in case user doesn't return to MyEvents
            self.service.joinEvent(event)
            NotificationService.scheduleNotificationForEvent(event)
        }
        else {
            self.service.leaveEvent(event)
        }
 
        self.refreshEvents()
    }
    
    
     // MARK: - Navigation     
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let nav = segue.destination as? UINavigationController else { return }
        
        if segue.identifier == "toEventDetails" {
            let frame = nav.view.frame // force load root view controller
            guard let detailsController = nav.viewControllers[0] as? EventDisplayViewController else { return }
            guard let event = sender as? Event else { return }
            
            detailsController.alreadyJoined = false
            detailsController.delegate = self
            
            detailsController.event = event
        }
        else if segue.identifier == "toCreateEvent" {
            guard let controller = nav.viewControllers[0] as? CreateEventViewController else { return }
            controller.delegate = self
        }
     }
}

extension EventsViewController: CreateEventDelegate {
    func didCreateEvent() {
        self.tabBarController?.selectedIndex = 2
    }
}
