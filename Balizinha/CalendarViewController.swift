//
//  CalendarViewController.swift
// Balizinha
//
//  Created by Tom Strissel on 5/18/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Crashlytics
import Balizinha

class CalendarViewController: UITableViewController {
    
    var sortedUpcomingEvents: [Balizinha.Event] = []
    var sortedPastEvents: [Balizinha.Event] = []
    fileprivate var allEvents: [Balizinha.Event] = []
    
    fileprivate let activityOverlay: ActivityIndicatorOverlay = ActivityIndicatorOverlay()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshEvents()
        self.listenFor(NotificationType.EventsChanged, action: #selector(self.refreshEvents), object: nil)
        
        self.navigationItem.title = "Calendar"
        
        activityOverlay.setup(frame: view.frame)
        view.addSubview(activityOverlay)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
        activityOverlay.setup(frame: frame)
    }

    @objc func refreshEvents() {
        EventService.shared.getEvents(type: nil) { [weak self] (results) in
            // completion function will get called once at the start, and each time events change
            guard let weakself = self else { return }
            // 1: sort all events by time, ascending
            weakself.allEvents = results.sorted { (event1, event2) -> Bool in
                guard let startTime1 = event1.startTime, let startTime2 = event2.startTime else { return true }
                return startTime1.timeIntervalSince(startTime2) < 0
            }
            
            guard let user = AuthService.currentUser else {
                weakself.sortedUpcomingEvents = weakself.allEvents
                return
            }
            // 2: Remove events the user has joined
            EventService.shared.getEvents(for: user, completion: {[weak self] (eventIds) in
                guard let weakself = self else { return }
                let original = weakself.allEvents.filter({ (event) -> Bool in
                    eventIds.contains(event.id)
                })
                
                weakself.sortedPastEvents = original.filter({ (event) -> Bool in
                    event.isPast
                }).sorted(by: { (e1, e2) -> Bool in
                    // sort past events in descending time
                    guard let startTime1 = e1.startTime, let startTime2 = e2.startTime else { return true }
                    return startTime1.timeIntervalSince(startTime2) > 0
                })
                
                weakself.sortedUpcomingEvents = original.filter({ (event) -> Bool in
                    !event.isPast
                })
                if #available(iOS 10.0, *) {
                    NotificationService.shared.refreshNotifications(self?.sortedUpcomingEvents)
                }
                weakself.tableView.reloadData()
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
        view.backgroundColor = UIColor.darkGreen
        let label = UILabel(frame: CGRect(x: 8, y: 0, width: tableView.frame.size.width - 16, height: 30))
        label.backgroundColor = .clear
        view.addSubview(label)
        label.font = UIFont.montserratMedium(size: 18)
        label.textColor = UIColor.offWhite
        view.clipsToBounds = true
        
        switch section {
        case 0:
            label.text = "Upcoming games"
        case 1:
            label.text = "Past games"
        default:
            label.text = nil
        }
        return view
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
        guard let event = sender as? Balizinha.Event else { return }
        
        detailsController.alreadyJoined = true
        
        detailsController.event = event
        
    }
    
}

extension CalendarViewController: EventCellDelegate {    
    // MARK: EventCellDelegate
    func joinOrLeaveEvent(_ event: Balizinha.Event, join: Bool) {
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
    
    func editEvent(_ event: Balizinha.Event) {
        guard let controller = UIStoryboard(name: "Events", bundle: nil).instantiateViewController(withIdentifier: "CreateEventViewController") as? CreateEventViewController else { return }
        controller.eventToEdit = event
        let nav = UINavigationController(rootViewController: controller)
        self.present(nav, animated: true, completion: nil)
    }
    
    func leaveEvent(_ event: Balizinha.Event) {
        guard let player = PlayerService.shared.current.value else { return }
        activityOverlay.show()
        EventService.shared.leaveEvent(event, userId: player.id) { [weak self] (error) in
            if let error = error as NSError? {
                DispatchQueue.main.async {
                    self?.activityOverlay.hide()
                    self?.simpleAlert("Could not leave game", defaultMessage: "There was an error while trying to leave this game.", error: error)
                }
            } else {
                DispatchQueue.main.async {
                    self?.activityOverlay.hide()
                    if #available(iOS 10.0, *) {
                        NotificationService.shared.removeNotificationForEvent(event)
                        NotificationService.shared.removeNotificationForDonation(event)
                    }
                }
            }
        }
    }
    
    func previewEvent(_ event: Balizinha.Event) {
        // nothing
    }
}


