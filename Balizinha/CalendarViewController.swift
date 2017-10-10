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
            EventService.shared.getEventsForUser(firAuth.currentUser!, completion: { (eventIds) in
                self.sortedUpcomingEvents = self.sortedUpcomingEvents.filter({ (event) -> Bool in
                    eventIds.contains(event.id)
                })
                
                let original = self.sortedUpcomingEvents
                self.sortedPastEvents = original.filter({ (event) -> Bool in
                    event.isPast
                }).sorted(by: { (e1, e2) -> Bool in
                    guard let startTime1 = e1.startTime, let startTime2 = e2.startTime else { return true }
                    return startTime1.timeIntervalSince(startTime2) > 0
                })
                
                self.sortedUpcomingEvents = original.filter({ (event) -> Bool in
                    !event.isPast
                })
                if #available(iOS 10.0, *) {
                    NotificationService.refreshNotifications(self.sortedUpcomingEvents)
                }
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
        cell.donationDelegate = self
        
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

        if indexPath.section == 0 {
            let event = sortedUpcomingEvents[indexPath.row]
            self.performSegue(withIdentifier: "toMyEventDetails", sender: event)
        }
        else if indexPath.section == 1 {
            let event = sortedPastEvents[indexPath.row]
            self.performSegue(withIdentifier: "toMyEventDetails", sender: event)
        }
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
        if event.paymentRequired {
            let alert = UIAlertController(title: "Are you sure?", message: "You are leaving a game that you've already paid for.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Leave game", style: .default, handler: { (action) in
                self.leaveEvent(event)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
        else {
            self.leaveEvent(event)
        }
        
        self.refreshEvents()
    }
    
    func editEvent(_ event: Event) {
        guard let controller = UIStoryboard(name: "Events", bundle: nil).instantiateViewController(withIdentifier: "CreateEventViewController") as? CreateEventViewController else { return }
        controller.eventToEdit = event
        let nav = UINavigationController(rootViewController: controller)
        self.present(nav, animated: true, completion: nil)
    }
    
    func leaveEvent(_ event: Event) {
        EventService.shared.leaveEvent(event)
        if #available(iOS 10.0, *) {
            NotificationService.removeNotificationForEvent(event)
            NotificationService.removeNotificationForDonation(event)
        }
    }
}

// MARK: - Donations
extension CalendarViewController: EventDonationDelegate {
    func paidStatus(event: Event) -> Bool? {
        return false
    }

    func promptForDonation(event: Event) {
        guard let player = PlayerService.shared.current else { return }
        
        var title = "Hope you enjoyed the game"
        if let name = event.name {
            title = "Hope you enjoyed \(name)"
        }
        let alert = UIAlertController(title: title, message: "Thank you for playing with us, it was great seeing you on the court. Help keep the community going (donate $1 or more) and growing.", preferredStyle: .alert)
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "$1.00"
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if let textField = alert.textFields?[0], let text = textField.text, let amount = Double(text), let amountString = EventService.amountString(from: NSNumber(value: amount)) {
                print("Donating \(amountString)")
                
                StripeService().createCharge(for: event, amount: amount, player: player, completion: { (success, error) in
                    print("Donation completed \(success), has error \(error)")
                    if success {
                        // add an action
                        guard let user = firAuth.currentUser else { return }
                        ActionService.post(.donation, userId: user.uid, username: user.displayName, eventId: event.id, message: nil)

                        self.simpleAlert("Thank you for your donation", message: "Your donation of \(amountString) will go a long way to keep Balizinha a great community!")
                    }
                    else if let error = error as? NSError{
                        self.simpleAlert("Could not donate", defaultMessage: "There was an issue with donating.", error: error)
                    }
                })
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    fileprivate func loadDonationStatus() {
//        EventService.shared.getEventPayments(type: nil) { (results) in
//        }
    }
}
