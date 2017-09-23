//
//  EventCell.swift
// Balizinha
//
//  Created by Tom Strissel on 5/18/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import AsyncImageView
import Stripe

protocol EventCellDelegate {
    func joinOrLeaveEvent(_ event: Event, join: Bool)
    func editEvent(_ event: Event)
    func paymentNeeded()
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
    var delegate: EventCellDelegate?
    
    var stripeService: StripeService?
    
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

        if !event.isPast {
            btnAction.isHidden = false
            // Button display and action
            if self.event!.userIsOwner {
                self.labelFull.text = "This is your event."
                self.btnAction.setTitle("Edit", for: UIControlState())
                self.btnAction.isEnabled = true
            }
            else if self.event!.containsUser(firAuth.currentUser!) {
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
        guard let event = self.event else { return }
        if event.userIsOwner {
            // edit
            self.delegate?.editEvent(event)
        }
        else {
            let join = !event.containsUser(firAuth.currentUser!)
            if join && event.paymentRequired {
                self.checkStripe()
            }
            else {
                self.delegate?.joinOrLeaveEvent(event, join: join)
            }
        }
    }
}

// MARK: - Payment
extension EventCell {
    func checkStripe() {
        if stripeService == nil {
            stripeService = StripeService()
        }
        stripeService?.loadPayment(host: nil)
        self.activityIndicator.startAnimating()
        self.btnAction.isEnabled = false
        self.btnAction.alpha = 0.5

        self.listenFor(NotificationType.PaymentContextChanged, action: #selector(refreshStripeStatus), object: nil)
    }
    
    func refreshStripeStatus() {
        guard let paymentContext = stripeService?.paymentContext else { return }
        if paymentContext.loading {
            self.activityIndicator.startAnimating()
            self.btnAction.isEnabled = false
            self.btnAction.alpha = 0.5
        }
        else {
            self.activityIndicator.stopAnimating()
            self.btnAction.isEnabled = true
            self.btnAction.alpha = 1
            if paymentContext.selectedPaymentMethod == nil {
                self.delegate?.paymentNeeded()
            }
            else {
                guard let user = firAuth.currentUser, let event = self.event else { return }
                self.delegate?.joinOrLeaveEvent(event, join: !event.containsUser(user))
            }
        }
    }
}
