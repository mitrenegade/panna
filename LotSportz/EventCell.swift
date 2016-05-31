//
//  EventCell.swift
//  LotSportz
//
//  Created by Tom Strissel on 5/18/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class EventCell: UITableViewCell {

    @IBOutlet var btnAction: UIButton!
    @IBOutlet var labelFull: UILabel!
    @IBOutlet var labelAttendance: UILabel!
    @IBOutlet var labelLocation: UILabel!
    @IBOutlet var labelTime: UILabel!
    @IBOutlet var labelDate: UILabel!
    @IBOutlet var eventLogo: UIImageView!
    
    var event: Event?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.eventLogo.layer.cornerRadius = self.eventLogo.frame.size.height / 2
        self.eventLogo.layer.borderWidth = 1.0
        self.eventLogo.layer.masksToBounds = true
        
        self.btnAction.layer.cornerRadius = self.btnAction.frame.size.height / 5
    }

    func setupWithEvent(event: Event) {
        self.event = event
        let place = event.place()
        //let time = event.timeString()
        self.labelLocation.text = place
        self.labelDate.text = "Thurs May 5" //To-Do: Sanitize Date info from event.time
        self.labelTime.text = "12pm - 3pm" //To-Do: Add start/end time attributes for events
        self.labelFull.text = "You're going!" //To-Do: Add functionality whether or not event is full
        
        self.labelAttendance.text = "10 Attending" //To-Do: "\(event.maxPlayers()) Attending"
//        self.btnAction.tag = indexPath.row //tag uniquely identifies cell, and therefore, the event
        
        switch event.type() {
        case "Basketball":
            self.eventLogo.image = UIImage(named: "backetball")
        case "Soccer":
            self.eventLogo.image = UIImage(named: "soccer")
        case "Flag Football":
            self.eventLogo.image = UIImage(named: "football")
        default:
            self.eventLogo.hidden = true
        }
        /*
        switch indexPath.section {
        case 0:
            cell.btnAction.hidden = false
        case 1:
            cell.btnAction.hidden = true
        default:
            break
            
        }
         */

    }

    @IBAction func didTapCancel(sender: AnyObject) {
        print("Tapped Cancel/Join")
    }
}
