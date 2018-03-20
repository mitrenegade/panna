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
    var joiningEvent: Event?
    
    let disposeBag = DisposeBag()
    var recentLocation: CLLocation?
    var firstLoaded: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Events"
        
        let addButton = UIButton(type: .custom)
        addButton.setImage(UIImage.init(named: "plusIcon30")?.withRenderingMode(.alwaysTemplate), for: .normal)
        addButton.addTarget(self, action: #selector(self.didClickAddEvent(sender:)), for: .touchUpInside)
        addButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addButton)
        
        listenFor(NotificationType.EventsChanged, action: #selector(self.refreshEvents), object: nil)
        
        if LocationService.shared.shouldFilterNearbyEvents {
            LocationService.shared.observedLocation.subscribe(onNext: {[weak self] locationState in
                switch locationState {
                case .located(let location):
                    print("location \(location)")
                    if let recent = self?.recentLocation {
                        if recent.distance(from: location) > 100 {
                            self?.refreshEvents()
                        }
                    }
                    else {
                        self?.refreshEvents()
                    }
                    self?.recentLocation = location
                default:
                    print("no location yet")
                }
            }).disposed(by: disposeBag)
        } else {
            refreshEvents()
        }
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        activityIndicator.color = UIColor.red
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
    
    @objc func refreshEvents() {
        service.getEvents(type: nil) { [weak self] (results) in
            // completion function will get called once at the start, and each time events change
            self?.firstLoaded = true
            
            // 1: sort all events by time
            guard let strongself = self else { return }
            self?.allEvents = strongself.filterByDistance(events: results).sorted { (event1, event2) -> Bool in
                return event1.id > event2.id
            }
            
            // 2: Remove events the user has joined
            guard let user = AuthService.currentUser else { return }
            self?.service.getEventsForUser(user, completion: {[weak self] (eventIds) in
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
        guard LocationService.shared.shouldFilterNearbyEvents else { return events }
        
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
        tableView.reloadData()
    }
    
    @objc func didClickAddEvent(sender: Any?) {
        if let _ = OrganizerService.shared.current {
            // create event
            performSegue(withIdentifier: "toCreateEvent", sender: nil)
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
        return sortedEvents.keys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let eventType = eventTypes[section]
        let events = sortedEvents[eventType] ?? []
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
        guard let current = PlayerService.shared.current.value else {
            simpleAlert("Could not join event", message: "Please update your player profile!")
            return
        }
        guard current.name != nil else {
            if let tab = tabBarController, let controllers = tab.viewControllers, let viewController = controllers[0] as? ConfigurableNavigationController {
                viewController.loadDefaultRootViewController()
            }
            let alert = UIAlertController(title: "Could not join event", message: "You need to add your name before joining a game. Update your profile now?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {[weak self] (action) in
                self?.tabBarController?.selectedIndex = 0
            }))
            alert.addAction(UIAlertAction(title: "Not now", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            
            return
        }
        
        joiningEvent = event
        if event.paymentRequired && SettingsService.paymentRequired() {
            checkIfAlreadyPaid(for: event)
        }
        else {
            joinEvent(event)
        }
        refreshEvents()
    }
    
    func editEvent(_ event: Event) {
        // does not implement this
    }
    
    fileprivate func joinEvent(_ event: Event) {
        //add notification in case user doesn't return to MyEvents
        service.joinEvent(event)
        if #available(iOS 10.0, *) {
            NotificationService.shared.scheduleNotificationForEvent(event)
            
            if SettingsService.donation() {
                NotificationService.shared.scheduleNotificationForDonation(event)
            }
        }
        
        if UserDefaults.standard.bool(forKey: UserSettings.DisplayedJoinEventMessage.rawValue) == false {
            simpleAlert("You've joined a game", message: "You can go to your Calendar to see upcoming events.")
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
    func checkIfAlreadyPaid(for event: Event) {
        guard let current = PlayerService.shared.current.value else {
            simpleAlert("Could not make payment", message: "Please update your player profile!")
            return
        }
        guard joiningEvent != nil else {
            print("no longer joining event")
            return
        }
        activityIndicator.startAnimating()
        PaymentService().checkForPayment(for: event.id, by: current.id) { [weak self] (success) in
            if success {
                self?.activityIndicator.stopAnimating()
                self?.joinEvent(event)
            }
            else {
                self?.checkStripe()
            }
        }
    }
    
    func checkStripe() {
        listenFor(NotificationType.PaymentContextChanged, action: #selector(refreshStripeStatus), object: nil)
    }
    
    @objc func refreshStripeStatus() {
        guard let paymentContext = StripeService.shared.paymentContext.value else { return }
        if paymentContext.loading {
            activityIndicator.startAnimating()
        }
        else {
            activityIndicator.stopAnimating()
            if let paymentMethod = paymentContext.selectedPaymentMethod {
                guard let event = joiningEvent else {
                    simpleAlert("Invalid event", message: "Could not join event. Please try again.")
                    return
                }
                shouldCharge(for: event, payment: paymentMethod)
            }
            else {
                paymentNeeded()
            }
            stopListeningFor(NotificationType.PaymentContextChanged)
        }
    }
    
    func paymentNeeded() {
        let alert = UIAlertController(title: "No payment method available", message: "This event has a fee. Please add a payment method in your profile.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            // todo: go to account
        }))
        alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: { (action) in
        }))
        present(alert, animated: true, completion: nil)
    }
    
    fileprivate func calculateAmountForEvent(event: Event, completion:@escaping ((Double)->Void)) {
        let amount = event.amount?.doubleValue ?? 0
        if let promotionId = PlayerService.shared.current.value?.promotionId {
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
        calculateAmountForEvent(event: event) {[weak self] (amount) in
            guard let paymentString: String = EventService.amountString(from: NSNumber(value: amount)) else {
                self?.simpleAlert("Could not calculate payment", message: "Please let us know about this error.")
                return
            }
            let alert = UIAlertController(title: "Confirm payment", message: "Press Ok to pay \(paymentString) for this game.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { [weak self] (action) in
                self?.chargeAndWait(event: event, amount: amount)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            }))
            self?.present(alert, animated: true, completion: nil)
        }
    }
    
    func chargeAndWait(event: Event, amount: Double) {
        guard let current = PlayerService.shared.current.value else {
            simpleAlert("Could not make payment", message: "Please update your player profile!")
            return
        }
        activityIndicator.startAnimating()

        StripeService.shared.createCharge(for: event, amount: amount, player: current, completion: {[weak self] (success, error) in
            self?.activityIndicator.stopAnimating()
            if success {
                self?.joinEvent(event)
                self?.joiningEvent = nil
            }
            else if let error = error as? NSError {
                var errorMessage = ""
                if let errorString = error.userInfo["error"] as? String {
                    errorMessage = "Error: \(errorString)"
                }
                self?.simpleAlert("Could not join game", message: "There was an issue making a payment. \(errorMessage)")
            }
        })
    }
}

extension EventsViewController: CreateEventDelegate {
    func didCreateEvent() {
        tabBarController?.selectedIndex = 2
    }
}

// TODO: delete this after 0.5.0 has been widely adopted
fileprivate var subscriptionsUpdated: Bool = false
extension EventsViewController {
    func updateSubscriptionsOnce(_ eventIds: [String]) {
        guard !subscriptionsUpdated else { return }
        subscriptionsUpdated = true

        let userEvents = allEvents.filter({ (event) -> Bool in
            return eventIds.contains(event.id)
        }) ?? []

        let subscribed: Bool
        if UserDefaults.standard.value(forKey: kNotificationsDefaultsKey) == nil {
            subscribed = true
        } else {
            subscribed = UserDefaults.standard.bool(forKey: kNotificationsDefaultsKey)
        }
        
        if #available(iOS 10.0, *) {
            NotificationService.shared.registerForGeneralNotification(subscribed: subscribed)
        } else {
            // Fallback on earlier versions
        }
        
        for event in userEvents {
            if #available(iOS 10.0, *) {
                let shouldSubscribe = event.active && !event.isPast && subscribed
                NotificationService.shared.registerForEventNotifications(event: event, subscribed: shouldSubscribe)
            } else {
                // Fallback on earlier versions
            }
        }
    }
}
