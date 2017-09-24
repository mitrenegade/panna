//
//  EventsViewController.swift
// Balizinha
//
//  Created by Tom Strissel on 5/23/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Stripe
import Firebase

class EventsViewController: UITableViewController {

    var service = EventService.shared
    var allEvents : [Event] = []
    var sortedEvents: [EventType: [Event]] = [.event3v3: [], .event5v5: [], .event7v7: [], .event11v11: [], .other: []]
    let eventTypes: [EventType] = [.event3v3, .event5v5, .event7v7, .event11v11, .other]

    let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    
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
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = self.view.center
        self.view.addSubview(activityIndicator)
        activityIndicator.color = UIColor.red
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
            self.service.getEventsForUser(firAuth.currentUser!, completion: { (eventIds) in
                
                print("eventsForUser \(firAuth.currentUser!): \(eventIds)")

                for event in self.allEvents {
                    print("event id \(event.id) date \(event.dateString(event.endTime ?? Date())) past \(event.isPast)")
                }
                print("all events count \(self.allEvents.count)")
                
                self.allEvents = self.allEvents.filter({ (event) -> Bool in
                    (!eventIds.contains(event.id) && !event.isPast)
                })
                
                // 3: Organize events by type
                self.sortedEvents = [.event3v3: [], .event5v5: [], .event7v7: [], .event11v11: [], .other: []]
                
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
        guard let user = PlayerService.shared.current else { return }
        if !user.isOwner {
            let alert = UIAlertController(title: "Create an event?", message: "You must be a paid organizer to create a new game. Click to upgrade for free.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Go", style: UIAlertActionStyle.default, handler: { (action) in
                user.isOwner = true
                
                // create
                self.performSegue(withIdentifier: "toCreateEvent", sender: nil)
            }))
            self.navigationController?.present(alert, animated: true, completion: nil)
        }
        else {
            // create
            self.performSegue(withIdentifier: "toCreateEvent", sender: nil)
        }
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

extension EventsViewController {
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sortedEvents.keys.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let eventType = self.eventTypes[section]
        let events = self.sortedEvents[eventType] ?? []
        return events.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return eventTypes[section].rawValue
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : EventCell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventCell
        cell.delegate = self
        cell.paymentDelegate = self
        
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
        guard let current = PlayerService.shared.current else {
            self.simpleAlert("Could not join event", message: "Please update your player profile!")
            return
        }
        guard current.name != nil else {
            if let tab = self.tabBarController, let controllers = tab.viewControllers, let viewController = controllers[0] as? ConfigurableNavigationController {
                viewController.loadDefaultRootViewController()
            }
            let alert = UIAlertController(title: "Could not join event", message: "You need to add your name before joining a game. Update your profile now?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) in
                self.tabBarController?.selectedIndex = 0
            }))
            alert.addAction(UIAlertAction(title: "Not now", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            return
        }
        
        if join {
            self.joinEvent(event)
        }
        else {
            self.service.leaveEvent(event)
        }
 
        self.refreshEvents()
    }
    
    func editEvent(_ event: Event) {
        // does not implement this
    }
    
    fileprivate func joinEvent(_ event: Event) {
        //add notification in case user doesn't return to MyEvents
        self.service.joinEvent(event)
        NotificationService.scheduleNotificationForEvent(event)
        
        if UserDefaults.standard.bool(forKey: UserSettings.DisplayedJoinEventMessage.rawValue) == false {
            self.simpleAlert("You've joined a game", message: "You can go to your Calendar to see upcoming events.")
            UserDefaults.standard.set(true, forKey: UserSettings.DisplayedJoinEventMessage.rawValue)
            UserDefaults.standard.synchronize()
        }
    }
}

extension EventsViewController: EventPaymentDelegate {
    func paymentNeeded() {
        let alert = UIAlertController(title: "No payment method available", message: "This event has a fee. Please add a payment method in your profile.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            // todo: go to account
        }))
        alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: { (action) in
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func shouldCharge(for event: Event, payment: STPPaymentMethod) {
        let alert = UIAlertController(title: "Confirm payment", message: "Press Ok to pay $6.99 for this game.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            self.chargeAndWait(event: event)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func chargeAndWait(event: Event) {
        guard let current = PlayerService.shared.current else {
            self.simpleAlert("Could not make payment", message: "Please update your player profile!")
            return
        }
        self.activityIndicator.startAnimating()

        let ref = firRef.child("stripe_customers").child(current.id).child("charges").childByAutoId()
        let params:[AnyHashable: Any] = ["amount": 699]
        ref.updateChildValues(params)
        ref.observe(.value) { (snapshot: DataSnapshot) in
            if let info = snapshot.value as? [String: AnyObject], let status = info["status"] as? String {
                print("status \(status)")
                self.activityIndicator.stopAnimating()
                if status == "succeeded" {
                    self.joinEvent(event)
                }
                else {
                    var errorMessage = "Status \(status)"
                    if let error = info["error"] {
                        errorMessage = "\(errorMessage) Error \(error)"
                    }
                    self.simpleAlert("Could not join game", message: "There was an issue making a payment. \(errorMessage)")
                }
            }
        }
    }
}

extension EventsViewController: CreateEventDelegate {
    func didCreateEvent() {
        self.tabBarController?.selectedIndex = 2
    }
}
