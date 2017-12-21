//
//  EventCell.swift
// Balizinha
//
//  Created by Tom Strissel on 5/18/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import AsyncImageView

protocol EventCellDelegate: class {
    func joinOrLeaveEvent(_ event: Event, join: Bool)
    func editEvent(_ event: Event)
    func previewEvent(_ event: Event)
}

protocol EventDonationDelegate: class {
    func paidStatus(event: Event) -> Bool? // if nil, still loading/unknown
    func promptForDonation(event: Event)
}

typealias EventStatus = (isPast: Bool, userIsOwner: Bool, userJoined: Bool)

class EventCellViewModel: NSObject {
    func buttonTitle(eventStatus: EventStatus) -> String {
        guard !PlayerService.isAnonymous else {
            return "Preview"
        }
        
        switch eventStatus {
        case (true, false, true):
            if SettingsService.donation() {
                return "Pay" // donate
            }
            else {
                return ""
            }
        case (true, false, false):
            return ""
        case (true, true, _):
            return ""
        case (false, true, _):
            return "Edit"
        case (false, false, let containsUser):
            return containsUser ? "Leave" : "Join"
        }
    }
}

class EventCell: UITableViewCell {

    @IBOutlet var btnAction: UIButton!
    @IBOutlet var labelFull: UILabel!
    @IBOutlet var labelAttendance: UILabel!
    @IBOutlet var labelLocation: UILabel!
    @IBOutlet var labelName: UILabel!
    @IBOutlet var labelTimeDate: UILabel!
    @IBOutlet var eventLogo: AsyncImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var event: Event?
    weak var delegate: EventCellDelegate?
    weak var donationDelegate: EventDonationDelegate?
    
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
        let name = event.name ?? "Balizinha"
        let type = event.type.rawValue
        self.labelName.text = "\(name) (\(type))"
        if let startTime = event.startTime {
            self.labelTimeDate.text = "\(event.dateString(startTime)) \(event.timeString(startTime))"
        }
        else {
            self.labelTimeDate.text = "Date/Time TBD"
        }
        let place = event.place
        self.labelLocation.text = place
        
        if let url = event.photoUrl, let URL = URL(string: url) {
            self.eventLogo.imageURL = URL
        }
        else {
            self.eventLogo.imageURL = nil
            self.eventLogo.image = UIImage(named: "soccer")
        }

        let title = EventCellViewModel().buttonTitle(eventStatus: (event.isPast, event.userIsOrganizer, event.containsUser(firAuth.currentUser!)))
        self.btnAction.setTitle(title, for: .normal)
        btnAction.isHidden = false
        self.btnAction.alpha = 1

        if !event.isPast {
            // Button display and action

            if self.event!.userIsOrganizer {
                self.labelFull.text = "This is your event."
                self.btnAction.isEnabled = true
            }
            else if event.containsUser(firAuth.currentUser!) {
                self.labelFull.text = "You're going!" //To-Do: Add functionality whether or not event is full
                self.btnAction.isEnabled = true
            }
            else {
                if self.event!.isFull {
                    self.labelFull.text = "Event full"
                    self.btnAction.isEnabled = false
                }
                else {
                    self.labelFull.text = "Available"
                    self.btnAction.isEnabled = true
                }
            }
            self.labelAttendance.text = "\(self.event!.numPlayers) Attending"
        } else {
            self.labelFull.isHidden = true
            self.labelAttendance.text = "\(self.event!.numPlayers) Attended"
            
            if !event.userIsOrganizer && SettingsService.donation() {
                self.btnAction.isHidden = false
                if let paid = self.donationDelegate?.paidStatus(event: event) {
                    self.btnAction.isEnabled = !paid
                    self.btnAction.alpha = 1
                }
                else {
                    self.btnAction.isEnabled = false // loading
                    self.btnAction.alpha = 0.5
                }
            }
            else {
                self.btnAction.isHidden = true
            }
        }
    }

    @IBAction func didTapButton(_ sender: AnyObject) {
        print("Tapped Cancel/Join")
        guard let event = self.event else { return }
        guard !PlayerService.isAnonymous else {
            delegate?.previewEvent(event)
            return
        }

        if event.userIsOrganizer {
            // edit
            self.delegate?.editEvent(event)
        }
        else if !event.isPast {
            let join = !event.containsUser(firAuth.currentUser!)
            delegate?.joinOrLeaveEvent(event, join: join)
        }
        else {
            // donate
            if SettingsService.donation() {
                donationDelegate?.promptForDonation(event: event)
            }
        }
    }
}
