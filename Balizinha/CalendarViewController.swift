//
//  CalendarViewController.swift
// Balizinha
//
//  Created by Tom Strissel on 5/18/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Crashlytics

class CalendarViewController: UITableViewController {
    
    var sortedUpcomingEvents: [Event] = []
    var sortedPastEvents: [Event] = []
    
    let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)

    let stripeService = StripeService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshEvents()
        self.listenFor(NotificationType.EventsChanged, action: #selector(self.refreshEvents), object: nil)
        
        self.navigationItem.title = "Calendar"
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = self.view.center
        self.view.addSubview(activityIndicator)
        activityIndicator.color = UIColor.red
        
        stripeService.loadPayment(host: nil)
        
        self.navigationController?.navigationBar.backgroundColor = UIColor.darkGray
        tableView.backgroundColor = UIColor.darkGray
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func refreshEvents() {
        EventService.shared.getEvents(type: nil) { [weak self] (results) in
            // completion function will get called once at the start, and each time events change
            
            // 1: sort all events by time
            self?.sortedUpcomingEvents = results.sorted { (event1, event2) -> Bool in
                return event1.id < event2.id
            }
            
            guard let user = firAuth.currentUser else { return }
            // 2: Remove events the user has joined
            EventService.shared.getEventsForUser(user, completion: {[weak self] (eventIds) in
                self?.sortedUpcomingEvents = self?.sortedUpcomingEvents.filter({ (event) -> Bool in
                    eventIds.contains(event.id)
                }) ?? []
                
                let original = self?.sortedUpcomingEvents
                self?.sortedPastEvents = original?.filter({ (event) -> Bool in
                    event.isPast
                }).sorted(by: { (e1, e2) -> Bool in
                    guard let startTime1 = e1.startTime, let startTime2 = e2.startTime else { return true }
                    return startTime1.timeIntervalSince(startTime2) > 0
                }) ?? []
                
                for event in self?.sortedPastEvents ?? [] {
                    print("event \(event.id) owner \(event.userIsOrganizer)")
                }
                
                self?.sortedUpcomingEvents = original?.filter({ (event) -> Bool in
                    !event.isPast
                }) ?? []
                if #available(iOS 10.0, *) {
                    NotificationService.shared.refreshNotifications(self?.sortedUpcomingEvents)
                }
                self?.tableView.reloadData()
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
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 30))
        view.backgroundColor = UIColor.mediumGray
        let label = UILabel(frame: CGRect(x: 8, y: 0, width: tableView.frame.size.width - 16, height: 30))
        label.backgroundColor = .clear
        view.addSubview(label)
        label.font = UIFont.montserratMedium(size: 18)
        label.textColor = UIColor.offWhite
        view.clipsToBounds = true
        
        switch section {
        case 0:
            label.text = "Upcoming events"
        case 1:
            label.text = "Past events"
        default:
            label.text = nil
        }
        return view
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
            NotificationService.shared.removeNotificationForEvent(event)
            NotificationService.shared.removeNotificationForDonation(event)
        }
    }
    
    func previewEvent(_ event: Event) {
        // nothing
    }
}

// MARK: - Donations
extension CalendarViewController: EventDonationDelegate {
    func paidStatus(event: Event) -> Bool? {
        // used to enforce a user only paying once. not used right now - user can continue to pay
        // TODO: use charges/events/eventId endpoint to find out if a user has paid
        return false
    }

    func promptForDonation(eventId: String) {
        if let event = self.sortedPastEvents.filter({event in
            return event.id == eventId
        }).first {
            self.promptForDonation(event: event)
        }
        else {
            guard let user = firAuth.currentUser else { return }
            EventService.shared.getEventsForUser(user, completion: {[weak self] (eventIds) in
                guard eventIds.contains(eventId) else { return }
                EventService.shared.withId(id: eventId, completion: {[weak self] (event) in
                    if let event = event {
                        self?.promptForDonation(event: event)
                    }
                })
            })
        }
        
    }
    func promptForDonation(event: Event) {
        guard let player = PlayerService.shared.current else { return }
        guard SettingsService.donation() else { return }
        
        var title = "Hope you enjoyed the game"
        if let name = event.name {
            title = "Hope you enjoyed \(name)"
        }
        let alert = UIAlertController(title: title, message: "Thank you for playing with us, it was great seeing you on the court. Help keep the community keep growing by helping space rental.", preferredStyle: .alert)
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "$1.00"
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            guard let _ = self.stripeService.paymentContext?.selectedPaymentMethod else {
                self.promptForInvalidPaymentMethod(nil)
                return
            }
            if let textField = alert.textFields?[0], let text = textField.text, let amount = Double(text), let amountString = EventService.amountString(from: NSNumber(value: amount)) {
                print("Donating \(amountString)")
                
                self.activityIndicator.startAnimating()
                
                self.stripeService.createCharge(for: event, amount: amount, player: player, isDonation: true, completion: {[weak self] (success, error) in
                    self?.activityIndicator.stopAnimating()
                    print("Donation completed \(success), has error \(error)")
                    if success {
                        // add an action
                        guard let user = firAuth.currentUser else { return }
                        ActionService.post(.donation, userId: user.uid, username: user.displayName, eventId: event.id, message: nil)

                        self?.simpleAlert("Thank you for your payment", message: "Your payment of \(amountString) will go a long way to keep Balizinha a great community!")
                    }
                    else if let error = error as? NSError {
                        self?.promptForInvalidPaymentMethod(error)
                    }
                })
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    fileprivate func promptForInvalidPaymentMethod(_ error: NSError?) {
        if let error = error {
            if let msg = error.userInfo["error"] as? String, msg == "Cannot charge a customer that has no active card" {
                self.simpleAlert("Could not process payment", message: "No credit card available. Please add a payment method in your account settings!")
            }
            else {
                self.simpleAlert("Could not process payment", defaultMessage: "There was an issue with payment.", error: error)
            }
        }
        else {
            self.simpleAlert("Thanks for the thought", message: "You don't currently have a payment method set up. Please go to your account settings and add a credit card.")
        }
    }
    
    fileprivate func loadDonationStatus() {
//        EventService.shared.getEventPayments(type: nil) { (results) in
//        }
    }
}
