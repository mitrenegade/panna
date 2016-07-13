//
//  EventCell.swift
//  LotSportz
//
//  Created by Tom Strissel on 5/18/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

protocol EventCellDelegate {
    func joinOrLeaveEvent(event: Event, join: Bool)
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
        self.eventLogo.contentMode = .ScaleAspectFill
        
        self.btnAction.layer.cornerRadius = self.btnAction.frame.size.height / 5
    }

    func setupWithEvent(event: Event) {
        self.event = event
        let place = event.place()
        self.labelLocation.text = place
        self.labelDate.text = self.event?.dateString(event.startTime()) //To-Do: Sanitize Date info from event.time
        self.labelTime.text = self.event?.timeString(event.startTime()) //To-Do: Add start/end time attributes for events
        
        switch event.type() {
        case .Basketball:
            self.eventLogo.image = UIImage(named: "basketball")
        case .Soccer:
            self.eventLogo.image = UIImage(named: "soccer")
        case .FlagFootball:
            self.eventLogo.image = UIImage(named: "football")
        default:
            self.eventLogo.hidden = true
        }
        
        if !event.isPast() {
            // Button display and action
            if self.event!.containsUser(firAuth!.currentUser!) {
                self.labelFull.text = "You're going!" //To-Do: Add functionality whether or not event is full
                self.btnAction.setTitle("Leave", forState: .Normal)
                self.btnAction.enabled = true
            }
            else {
                self.btnAction.setTitle("Join", forState: .Normal)
                if self.event!.isFull() {
                    self.labelFull.text = "Event full"
                    self.btnAction.enabled = false
                }
                else {
                    self.labelFull.text = "Available"
                    self.btnAction.enabled = true
                }
            }
            // self.btnAction.tag = indexPath.row //tag uniquely identifies cell, and therefore, the event
            // TODO: hook up cancel or join behavior
            
            self.labelAttendance.text = "\(self.event!.numPlayers()) Attending"
        } else {
            self.labelFull.hidden = true
            self.btnAction.hidden = true
            self.labelAttendance.text = "\(self.event!.numPlayers()) Attended"
        }
    }

    @IBAction func didTapButton(sender: AnyObject) {
        print("Tapped Cancel/Join")
        self.delegate?.joinOrLeaveEvent(self.event!, join: !self.event!.containsUser(firAuth!.currentUser!))
    }
}
