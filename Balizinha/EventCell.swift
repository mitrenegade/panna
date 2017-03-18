//
//  EventCell.swift
// Balizinha
//
//  Created by Tom Strissel on 5/18/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

protocol EventCellDelegate {
    func joinOrLeaveEvent(_ event: Event, join: Bool)
}

class EventCell: UITableViewCell {

    @IBOutlet var btnAction: UIButton!
    @IBOutlet var labelFull: UILabel!
    @IBOutlet var labelAttendance: UILabel!
    @IBOutlet var labelLocation: UILabel!
    @IBOutlet var labelTime: UILabel!
    @IBOutlet var labelDate: UILabel!
    @IBOutlet var eventLogo: UIImageView!
    
    var event: Event?
    var delegate: EventCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.eventLogo.layer.cornerRadius = self.eventLogo.frame.size.height / 2
        self.eventLogo.layer.borderWidth = 1.0
        self.eventLogo.layer.masksToBounds = true
        self.eventLogo.contentMode = .scaleAspectFill
        
        self.btnAction.layer.cornerRadius = self.btnAction.frame.size.height / 5
    }

    func setupWithEvent(_ event: Event) {
        self.event = event
        let place = event.place
        self.labelLocation.text = place
        if let startTime = event.startTime {
            self.labelDate.text = event.dateString(startTime) //To-Do: Sanitize Date info from event.time
            self.labelTime.text = event.timeString(startTime) //To-Do: Add start/end time attributes for events
        }
        else {
            self.labelDate.text = "Date TBD"
            self.labelTime.text = "Time TBD"
        }
        
        if let url = event.photoUrl, let URL = URL(string: url) {
            do {
                let data = try Data(contentsOf: URL)
                if let image = UIImage(data: data) {
                    // only set if the cell is still for the same actionId
                    self.eventLogo.image = image
                }
                else {
                    self.eventLogo.image = UIImage(named: "soccer")
                }
            }
            catch {
                self.eventLogo.image = UIImage(named: "soccer")
            }
        }
        else {
            self.eventLogo.image = UIImage(named: "soccer")
        }

        if !event.isPast {
            // Button display and action
            if self.event!.userIsOwner {
                self.labelFull.text = "This is your event."
                self.btnAction.setTitle("Edit", for: UIControlState())
                self.btnAction.isEnabled = false
            }
            else if self.event!.containsUser(firAuth!.currentUser!) {
                self.labelFull.text = "You're going!" //To-Do: Add functionality whether or not event is full
                self.btnAction.setTitle("Leave", for: UIControlState())
                self.btnAction.isEnabled = true
            }
            else {
                self.btnAction.setTitle("Join", for: UIControlState())
                if self.event!.isFull {
                    self.labelFull.text = "Event full"
                    self.btnAction.isEnabled = false
                }
                else {
                    self.labelFull.text = "Available"
                    self.btnAction.isEnabled = true
                }
            }
            // self.btnAction.tag = indexPath.row //tag uniquely identifies cell, and therefore, the event
            // TODO: hook up cancel or join behavior
            
            self.labelAttendance.text = "\(self.event!.numPlayers) Attending"
        } else {
            self.labelFull.isHidden = true
            self.btnAction.isHidden = true
            self.labelAttendance.text = "\(self.event!.numPlayers) Attended"
        }
    }

    @IBAction func didTapButton(_ sender: AnyObject) {
        print("Tapped Cancel/Join")
        self.delegate?.joinOrLeaveEvent(self.event!, join: !self.event!.containsUser(firAuth!.currentUser!))
    }
}
