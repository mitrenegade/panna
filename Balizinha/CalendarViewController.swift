//
//  CalendarViewController.swift
// Balizinha
//
//  Created by Tom Strissel on 5/18/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class CalendarViewController: UITableViewController {
    
    var sortedUpcomingEvents: [Event] = []
    var sortedPastEvents: [Event] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshEvents()
        self.listenFor(NotificationType.EventsChanged, action: #selector(self.refreshEvents), object: nil)
        
        self.navigationItem.title = "Calendar"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func refreshEvents() {
        
        EventService.shared.getEvents(type: nil) { (results) in
            // completion function will get called once at the start, and each time events change
            
            // 1: sort all events by time
            self.sortedUpcomingEvents = results.sorted { (event1, event2) -> Bool in
                return event1.id < event2.id
            }
            
            // 2: Remove events the user has joined
            EventService.shared.getEventsForUser(firAuth!.currentUser!, completion: { (eventIds) in
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
}

extension CalendarViewController {
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 0 else {
            return
        }

        let event = sortedUpcomingEvents[indexPath.row]
        self.performSegue(withIdentifier: "toMyEventDetails", sender: event)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let nav = segue.destination as? ConfigurableNavigationController else { return }
        let frame = nav.view.frame // force viewDidLoad so viewControllers exists
        guard let detailsController = nav.viewControllers[0] as? EventDisplayViewController else { return }
        guard let event = sender as? Event else { return }
        
        detailsController.alreadyJoined = true
        detailsController.delegate = self
        
        detailsController.event = event
        
    }
    
}

extension CalendarViewController: EventCellDelegate {
    
    // MARK: EventCellDelegate
    func joinOrLeaveEvent(_ event: Event, join: Bool) {
        let user = firAuth!.currentUser!
        if join {
            EventService.shared.joinEvent(event, user: user)
        }
        else {
            EventService.shared.leaveEvent(event, user: user)
        }
        
        self.refreshEvents()
    }
}
