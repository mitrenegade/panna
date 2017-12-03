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
import CoreLocation
import RxSwift

class EventsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var service = EventService.shared
    var allEvents : [Event] = []
    var sortedEvents: [EventType: [Event]] = [.event3v3: [], .event5v5: [], .event7v7: [], .event11v11: [], .other: []]
    let eventTypes: [EventType] = [.event3v3, .event5v5, .event7v7, .event11v11, .other]

    let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    var stripeService: StripeService = StripeService()
    var joiningEvent: Event?
    
    let disposeBag = DisposeBag()
    var recentLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Events"
        
        let addButton = UIButton(type: .custom)
        addButton.setImage(UIImage.init(named: "plusIcon30"), for: .normal)
        addButton.addTarget(self, action: #selector(self.didClickAddEvent(sender:)), for: .touchUpInside)
        addButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addButton)
        
        self.listenFor(NotificationType.EventsChanged, action: #selector(self.refreshEvents), object: nil)
        LocationService.shared.observedLocation.subscribe(onNext: { locationState in
            switch locationState {
            case .located(let location):
                print("location \(location)")
                if let recent = self.recentLocation {
                    if recent.distance(from: location) > 100 {
                        self.refreshEvents()
                    }
                }
                else {
                    self.refreshEvents()
                }
                self.recentLocation = location
            default:
                print("no location yet")
            }
        }).addDisposableTo(disposeBag)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = self.view.center
        self.view.addSubview(activityIndicator)
        activityIndicator.color = UIColor.red
    }
    
    deinit {
        print("eventsView deinit")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 10.0, *) {
            NotificationService.shared.resetBadgeCount()
        } else {
            // Fallback on earlier versions
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    func refreshEvents() {
        service.getEvents(type: nil) { [weak self] (results) in
            // completion function will get called once at the start, and each time events change
            
            // 1: sort all events by time
            guard let strongself = self else { return }
            self?.allEvents = strongself.filterByDistance(events: results).sorted { (event1, event2) -> Bool in
                return event1.id > event2.id
            }
            
            // 2: Remove events the user has joined
            self?.service.getEventsForUser(firAuth.currentUser!, completion: {[weak self] (eventIds) in
                
                print("eventsForUser \(firAuth.currentUser!): \(eventIds)")
                print("all events count \(self?.allEvents.count)")
                
                // version 0.5.0: for users installing a notification-enabled app for the first time, make sure events they've joined or created in the past have the correct subscriptions
                self?.updateSubscriptionsOnce(eventIds)

                self?.allEvents = self?.allEvents.filter({ (event) -> Bool in
                    (!eventIds.contains(event.id) && !event.isPast)
                }) ?? []
                
                // 3: Organize events by type
                self?.sortedEvents = [.event3v3: [], .event5v5: [], .event7v7: [], .event11v11: [], .other: []]
                
                for event in self?.allEvents ?? [] {
                    var oldValue = self?.sortedEvents[event.type]
                    print(event.type)
                    oldValue?.append(event)
                    self?.sortedEvents.updateValue(oldValue!, forKey: event.type)
                }
                self?.reloadData()
            })
        }
    }
    
    fileprivate func filterByDistance(events: [Event]) -> [Event]{
        guard let location = LocationService.shared.lastLocation else { return events }
        guard !TESTING else {
            return events
        }
        let filtered = events.filter { (event) -> Bool in
            guard let lat = event.lat, let lon = event.lon else {
                print("filtered event \(event.name) no lat lon")
                return true
            }
            let coord = CLLocation(latitude: lat, longitude: lon)
            let dist = coord.distance(from: location)
            print("filtered event \(event.name) coord \(coord) dist \(dist)")
            return dist < Double(SettingsService.eventFilterRadius * METERS_PER_MILE)
        }
        return filtered
    }
    
    func reloadData() {
        self.tableView.reloadData()
    }
    
    func didClickAddEvent(sender: Any) {
        if let _ = OrganizerService.shared.current {
            // create event
            self.performSegue(withIdentifier: "toCreateEvent", sender: nil)
        }
        else {
            // create organizer
            var message = "You must be an organizer to create a new game. Click now to start organizing games for free."
            if SettingsService.paymentRequired() {
                message = "You must be an organizer to create a new game. Click now to start a month long free trial."
            }
            let alert = UIAlertController(title: "Become an Organizer?", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Start", style: UIAlertActionStyle.default, handler: { (action) in
                
                // TODO: check for payment method before creating an organizer?
                OrganizerService.shared.createOrganizer(completion: {[weak self] (organizer, error) in
                    if let error = error {
                        self?.simpleAlert("Could not become organizer", message: "There was an issue joining the organizer trial. \(error.localizedDescription)")
                    }
                    else {
                        // go directly to create event without payments
                        guard SettingsService.paymentRequired() else {
                            self?.performSegue(withIdentifier: "toCreateEvent", sender: nil)
                            return
                        }
                        
                        // create
                        self?.stripeService.createSubscription(completion: { [weak self] (success, error) in
                            print("Success \(success) error \(error)")
                            var title: String = "Free trial started"
                            var message: String = "Good luck organizing games! You are now in the 30 day organizer trial."
                            if let error = error {
                                // TODO: handle credit card payment after organizer was created!
                                // should allow users to organize for now, and ask to add a payment later
                                // should stop allowing it once their trial is up
                                title = "Payment needed"
                                message = "You are in a free trial and can still organize games but please add a payment within 30 days."
                            }
                            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) in
                                self?.performSegue(withIdentifier: "toCreateEvent", sender: nil)
                            }))
                            self?.present(alert, animated: true, completion: nil)
                        })
                    }
                })
            }))
            self.navigationController?.present(alert, animated: true, completion: nil)
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

extension EventsViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sortedEvents.keys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let eventType = self.eventTypes[section]
        let events = self.sortedEvents[eventType] ?? []
        return events.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return eventTypes[section].rawValue
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : EventCell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventCell
        cell.delegate = self
        
        let event = sortedEvents[eventTypes[indexPath.section]]![indexPath.row]
        cell.setupWithEvent(event)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        let list = sortedEvents[eventTypes[section]]
        return list!.count == 0 ? 0 : UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
        
        self.joiningEvent = event
        if event.paymentRequired && SettingsService.paymentRequired() {
            self.checkStripe()
        }
        else {
            self.joinEvent(event)
        }
        self.refreshEvents()
    }
    
    func editEvent(_ event: Event) {
        // does not implement this
    }
    
    fileprivate func joinEvent(_ event: Event) {
        //add notification in case user doesn't return to MyEvents
        self.service.joinEvent(event)
        if #available(iOS 10.0, *) {
            NotificationService.shared.scheduleNotificationForEvent(event)
            
            if SettingsService.donation() {
                NotificationService.shared.scheduleNotificationForDonation(event)
            }
        }
        
        if UserDefaults.standard.bool(forKey: UserSettings.DisplayedJoinEventMessage.rawValue) == false {
            self.simpleAlert("You've joined a game", message: "You can go to your Calendar to see upcoming events.")
            UserDefaults.standard.set(true, forKey: UserSettings.DisplayedJoinEventMessage.rawValue)
            UserDefaults.standard.synchronize()
        }
    }
    
    func previewEvent(_ event: Event) {
        // nothing
    }
}

// MARK: - Payments
extension EventsViewController {
    func checkStripe() {
        stripeService.loadPayment(host: nil)
        self.activityIndicator.startAnimating()
        
        self.listenFor(NotificationType.PaymentContextChanged, action: #selector(refreshStripeStatus), object: nil)
    }
    
    func refreshStripeStatus() {
        guard let paymentContext = stripeService.paymentContext else { return }
        if paymentContext.loading {
            self.activityIndicator.startAnimating()
        }
        else {
            self.activityIndicator.stopAnimating()
            if let paymentMethod = paymentContext.selectedPaymentMethod {
                guard let event = self.joiningEvent else {
                    simpleAlert("Invalid event", message: "Could not join event. Please try again.")
                    return
                }
                self.shouldCharge(for: event, payment: paymentMethod)
            }
            else {
                self.paymentNeeded()
            }
            self.stopListeningFor(NotificationType.PaymentContextChanged)
        }
    }
    
    func paymentNeeded() {
        let alert = UIAlertController(title: "No payment method available", message: "This event has a fee. Please add a payment method in your profile.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            // todo: go to account
        }))
        alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: { (action) in
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func calculateAmountForEvent(event: Event, completion:@escaping ((Double)->Void)) {
        let amount = event.amount?.doubleValue ?? 0
        if let promotionId = PlayerService.shared.current?.promotionId {
            PromotionService.shared.withId(id: promotionId, completion: { (promotion, error) in
                if let promotion = promotion, let discount = promotion.discountFactor {
                    print("Event cost with discount of \(discount) = \(amount * discount)")
                    completion(amount * discount)
                }
                else {
                    print("Event cost either has no promotion or no discount. Error: \(error)")
                    completion(amount)
                }
            })
        }
        else {
            print("Event cost has no promotion")
            completion(amount)
        }
    }
    
    func shouldCharge(for event: Event, payment: STPPaymentMethod) {
        calculateAmountForEvent(event: event) { (amount) in
            guard let paymentString: String = EventService.amountString(from: NSNumber(value: amount)) else {
                self.simpleAlert("Could not calculate payment", message: "Please let us know about this error.")
                return
            }
            let alert = UIAlertController(title: "Confirm payment", message: "Press Ok to pay \(paymentString) for this game.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                self.chargeAndWait(event: event, amount: amount)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func chargeAndWait(event: Event, amount: Double) {
        guard let current = PlayerService.shared.current else {
            self.simpleAlert("Could not make payment", message: "Please update your player profile!")
            return
        }
        self.activityIndicator.startAnimating()

        stripeService.createCharge(for: event, amount: amount, player: current, completion: {[weak self] (success, error) in
            self?.activityIndicator.stopAnimating()
            if success {
                self?.joinEvent(event)
            }
            else if let error = error as? NSError {
                var errorMessage = ""
                if let errorString = error.userInfo["error"] as? String {
                    errorMessage = "Error \(errorString)"
                }
                self?.simpleAlert("Could not join game", message: "There was an issue making a payment. \(errorMessage)")
            }
        })
    }
}

extension EventsViewController: CreateEventDelegate {
    func didCreateEvent() {
        self.tabBarController?.selectedIndex = 2
    }
}

// TODO: delete this after 0.5.0 has been widely adopted
fileprivate var subscriptionsUpdated: Bool = false
extension EventsViewController {
    func updateSubscriptionsOnce(_ eventIds: [String]) {
        guard !subscriptionsUpdated else { return }
        subscriptionsUpdated = true

        let userEvents = self.allEvents.filter({ (event) -> Bool in
            return eventIds.contains(event.id)
        }) ?? []

        for event in userEvents {
            if #available(iOS 10.0, *) {
                let shouldSubscribe = event.active && !event.isPast
                NotificationService.shared.registerForEventNotifications(event: event, subscribed: shouldSubscribe)
            } else {
                // Fallback on earlier versions
            }
        }
    }
}
