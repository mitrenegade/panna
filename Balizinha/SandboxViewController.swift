//
//  SandboxViewController.swift
//  LotSportz
//
//  Created by Bobby Ren on 5/12/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import SWRevealViewController

class SandboxViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var menuButton: UIBarButtonItem!

    var service = EventService.sharedInstance()
    var events: [String: Event] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        service.getEvents(type: nil) { (results) in
            // completion function will get called once at the start, and each time events change
            for event: Event in results {
                // make sure events is unique and don't add duplicates
                if let id = event.id as? String {
                    self.events[id] = event
                }
                else {
                    print("what is id? \(event.id)")
                }
            }
            self.tableView.reloadData()
        }
        
        // Do any additional setup after loading the view.
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
        }
        
        // TODO: Create two listeners with an actual query filter and see if it works
    }

    // MARK: - Button actions
    @IBAction func didClickCreate() {
//        service.createEvent(eventDict: nil)
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath)
        let sortedEvents = events.values.sorted { (event1, event2) -> Bool in
            return event1.id > event2.id
        }
        let event = sortedEvents[indexPath.row]
        let type = event.type
        let place = event.place
        let time = event.timeString(event.startTime)
        cell.textLabel!.text = "\(type) at \(place)"
        cell.detailTextLabel?.text = time
        
        return cell
    }
}
