//
//  EventsViewController.swift
// Balizinha
//
//  Created by Tom Strissel on 5/23/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseDatabase
import CoreLocation
import RxSwift
import Balizinha

class EventsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var service = EventService.shared
    var joinHelper = JoinEventHelper()
    var allEvents : [Balizinha.Event] = []
    var sortedEvents: [EventType: [Balizinha.Event]] = [:]
    let eventOrder: [EventType] = [.event3v3, .event5v5, .event7v7, .event11v11, .group, .social, .other]

    fileprivate let activityOverlay: ActivityIndicatorOverlay = ActivityIndicatorOverlay()
    
    let disposeBag = DisposeBag()
    var recentLocation: CLLocation?
    var firstLoaded: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Games"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didClickAddEvent(sender:)))
        
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
        
        activityOverlay.setup(frame: self.view.frame)
        view.addSubview(activityOverlay)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationService.shared.resetBadgeCount()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        activityOverlay.setup(frame: self.view.frame)
    }
    
    @objc func refreshEvents() {
        if SettingsService.usesGetAvailableEvents() {
            service.getAvailableEvents { [weak self] (results) in
                print("Results count \(results.count)")
                self?.handleEvents(results)
            }
        } else {
            service.getEvents(type: nil) { [weak self] (results) in
                print("Results count \(results.count)")
                self?.handleEvents(results)
            }
        }
    }
    
    fileprivate func handleEvents(_ results: [Balizinha.Event]) {
        // completion function will get called once at the start, and each time events change
        firstLoaded = true
        
        // 1: sort all events by time
        allEvents = filterByDistance(events: results).sorted { (event1, event2) -> Bool in
            // ascending time
            guard let startTime1 = event1.startTime, let startTime2 = event2.startTime else { return true }
            return startTime1.timeIntervalSince(startTime2) < 0
        }
        
        // 2: Remove events the user has joined
        guard let user = AuthService.currentUser else { return }
        service.getEvents(for: user, completion: {[weak self] (eventIds) in
            guard let weakself = self else { return }
            
            weakself.allEvents = weakself.allEvents.filter({ (event) -> Bool in
                (!eventIds.contains(event.id) && !event.isPast)
            })
            
            // 3: Organize events by type
            weakself.sortedEvents = [.event3v3: [], .event5v5: [], .event7v7: [], .event11v11: [], .group: [], .social: [], .other: []]
            
            for event in weakself.allEvents {
                if weakself.eventOrder.contains(event.type) {
                    var eventArray = weakself.sortedEvents[event.type] ?? []
                    eventArray.append(event)
                    weakself.sortedEvents.updateValue(eventArray, forKey: event.type)
                } else {
                    var eventArray = weakself.sortedEvents[.other] ?? []
                    eventArray.append(event)
                    weakself.sortedEvents.updateValue(eventArray, forKey: .other)
                }
            }
            weakself.reloadData()
        })
    }
    
    fileprivate func filterByDistance(events: [Balizinha.Event]) -> [Balizinha.Event]{
        guard let location = LocationService.shared.lastLocation else { return events }
        guard LocationService.shared.shouldFilterNearbyEvents else { return events }
        
        let filtered = events.filter { (event) -> Bool in
            guard let lat = event.lat, let lon = event.lon else {
                print("filtered event \(String(describing: event.name)) no lat lon")
                return true
            }
            let coord = CLLocation(latitude: lat, longitude: lon)
            let dist = coord.distance(from: location)
            print("filtered event \(String(describing: event.name)) coord \(coord) dist \(dist)")
            return dist < Double(SettingsService.eventFilterRadius * METERS_PER_MILE)
        }
        return filtered
    }
    
    func reloadData() {
        tableView.reloadData()
    }
    
    @objc func didClickAddEvent(sender: Any?) {
        // create event
        performSegue(withIdentifier: "toCreateEvent", sender: nil)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let nav = segue.destination as? UINavigationController else { return }
        
        if segue.identifier == "toEventDetails" {
            _ = nav.view.frame // force load root view controller
            guard let detailsController = nav.viewControllers[0] as? EventDisplayViewController else { return }
            guard let event = sender as? Balizinha.Event else { return }
            
            detailsController.event = event
            detailsController.delegate = self
        }
        else if segue.identifier == "toCreateEvent" {
            guard let controller = nav.viewControllers[0] as? EventLeagueSelectorViewController else { return }
            controller.delegate = self
        }
    }
}

extension EventsViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return eventOrder.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let eventType = eventOrder[section]
        let events = sortedEvents[eventType] ?? []
        return events.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return eventOrder[section].rawValue
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : EventCell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventCell
        cell.delegate = self
        
        let eventType = eventOrder[indexPath.section]
        guard let array = sortedEvents[eventType], indexPath.row < array.count else { return cell }
        let event = array[indexPath.row]
        cell.setupWithEvent(event)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section < eventOrder.count else { return 0 }
        let array = sortedEvents[eventOrder[section]] ?? []
        return array.isEmpty ? 0 : UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let eventType = eventOrder[indexPath.section]
        guard let array = sortedEvents[eventType], indexPath.row < array.count else { return }

        let event = array[indexPath.row]
        performSegue(withIdentifier: "toEventDetails", sender: event)
    }
}

extension EventsViewController: EventCellDelegate {
    // MARK: EventCellDelegate
    func joinOrLeaveEvent(_ event: Balizinha.Event, join: Bool) {
        guard let current = PlayerService.shared.current.value else {
            simpleAlert("Could not join event", message: "Please update your player profile!")
            return
        }
        guard current.name != nil else {
            if let tab = tabBarController, let controllers = tab.viewControllers, let viewController = controllers[0] as? ConfigurableNavigationController {
                viewController.loadDefaultRootViewController()
            }
            let alert = UIAlertController(title: "Please add your name", message: "Before joining a game, it'll be nice to know who you are. Update your profile now?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {[weak self] (action) in
                self?.goToAddName()
            }))
            alert.addAction(UIAlertAction(title: "Not now", style: .cancel, handler: { _ in
                self.doJoinEvent(event)
            }))
            present(alert, animated: true, completion: nil)
            
            return
        }
        doJoinEvent(event)
    }
    
    fileprivate func doJoinEvent(_ event: Balizinha.Event) {
        joinHelper.event = event
        joinHelper.rootViewController = self
        joinHelper.delegate = self
        joinHelper.checkIfPartOfLeague()
        refreshEvents()
    }
    
    func editEvent(_ event: Balizinha.Event) {
        // does not implement this
    }
    
    func previewEvent(_ event: Balizinha.Event) {
        // nothing
    }
}

// MARK: - Profile
extension EventsViewController {
    fileprivate func goToAddName() {
        guard let url = URL(string: "panna://account/profile") else { return }
        DeepLinkService.shared.handle(url: url)
    }
}

extension EventsViewController: CreateEventDelegate {
    func eventsDidChange() {
        tabBarController?.selectedIndex = 2
        if let nav = tabBarController?.viewControllers?[2] as? UINavigationController, let controller = nav.viewControllers[0] as? CalendarViewController {
            controller.refreshEvents()
        }
    }
}

extension EventsViewController: JoinEventDelegate {
    func didJoin(_ event: Balizinha.Event?) {
        // only used to display message
        let title: String
        let message: String
        if UserDefaults.standard.bool(forKey: UserSettings.DisplayedJoinEventMessage.rawValue) == false {
            title = "You've joined a game!"
            message = "You can go to your Calendar to see upcoming games."
            UserDefaults.standard.set(true, forKey: UserSettings.DisplayedJoinEventMessage.rawValue)
            UserDefaults.standard.synchronize()
        } else {
            if let name = event?.name {
                title = "You've joined \(name)"
            } else {
                title = "You've joined a game!"
            }
            message = ""
        }
        simpleAlert(title, message: message, completion: {
        })
    }
    
    func startActivityIndicator() {
        activityOverlay.show()
    }
    
    func stopActivityIndicator() {
        activityOverlay.hide()
    }
    
    func didCancelPayment() {
        stopActivityIndicator()
    }
}

extension EventsViewController: EventDetailsDelegate {
    func didClone(event: Balizinha.Event) {
        dismiss(animated: true) {
            guard let controller = UIStoryboard(name: "Events", bundle: nil).instantiateViewController(withIdentifier: "CreateEventViewController") as? CreateEventViewController else { return }
            controller.delegate = self
            controller.eventToClone = event
            
            let nav = UINavigationController(rootViewController: controller)
            self.present(nav, animated: true, completion: nil)
        }
    }
}
