//
//  EventCell.swift
// Balizinha
//
//  Created by Tom Strissel on 5/18/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

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
        guard !AuthService.isAnonymous else {
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
    
    var buttonFont: UIFont {
        guard !AuthService.isAnonymous else {
            return UIFont.montserrat(size: 13)
        }
        return UIFont.montserrat(size: 16)
    }
}

class EventCell: UITableViewCell {

    @IBOutlet var btnAction: UIButton!
    @IBOutlet var labelFull: UILabel!
    @IBOutlet var labelAttendance: UILabel!
    @IBOutlet var labelLocation: UILabel!
    @IBOutlet var labelName: UILabel!
    @IBOutlet var labelTimeDate: UILabel!
    @IBOutlet var eventLogo: RAImageView!
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
        
        // TODO this is too layered, how to check for either url without doing so many web requests? so many if/else?
        FirebaseImageService().eventPhotoUrl(for: event) { [weak self] (url) in
            DispatchQueue.main.async {
                if let urlString = url?.absoluteString {
                    self?.eventLogo.imageUrl = urlString
                } else if let urlString = event.photoUrl {
                    // fall back on photoUrl
                    self?.eventLogo.imageUrl = urlString
                } else if let leagueId = event.league {
                    FirebaseImageService().leaguePhotoUrl(for: leagueId) { [weak self] (url) in
                        DispatchQueue.main.async {
                            if let urlString = url?.absoluteString {
                                self?.eventLogo.imageUrl = urlString
                            } else {
                                self?.eventLogo.imageUrl = nil
                                self?.eventLogo.image = UIImage(named: "soccer")
                            }
                        }
                    }
                } else {
                    self?.eventLogo.imageUrl = nil
                    self?.eventLogo.image = UIImage(named: "soccer")
                }
            }
        }

        let containsUser: Bool
        if let player = PlayerService.shared.current.value {
            containsUser = event.containsPlayer(player)
        } else {
            containsUser = false
        }
        
        let viewModel = EventCellViewModel()
        let title = viewModel.buttonTitle(eventStatus: (event.isPast, event.userIsOrganizer, containsUser))
        btnAction.setTitle(title, for: .normal)
        btnAction.isHidden = false
        btnAction.alpha = 1

        let font = viewModel.buttonFont
        btnAction.titleLabel?.font = font

        if !event.isPast {
            // Button display and action

            if self.event!.userIsOrganizer {
                self.labelFull.text = "This is your event."
                self.btnAction.isEnabled = true
                btnAction.alpha = 1
            }
            else if containsUser {
                self.labelFull.text = "You're going!" //To-Do: Add functionality whether or not event is full
                self.btnAction.isEnabled = true
                btnAction.alpha = 1
            }
            else {
                if self.event!.isFull {
                    self.labelFull.text = "Event full"
                    self.btnAction.isEnabled = false
                    if !AuthService.isAnonymous {
                        btnAction.alpha = 0.5
                    }
                }
                else {
                    self.labelFull.text = "Available"
                    self.btnAction.isEnabled = true
                    btnAction.alpha = 1
                }
            }
            self.labelAttendance.text = "\(self.event!.numPlayers)"
        } else {
            self.labelFull.isHidden = true
            self.labelAttendance.text = "\(self.event!.numPlayers)"
            
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
        guard !AuthService.isAnonymous else {
            delegate?.previewEvent(event)
            return
        }

        if event.userIsOrganizer {
            // edit
            self.delegate?.editEvent(event)
        }
        else if !event.isPast {
            let containsUser: Bool
            if let player = PlayerService.shared.current.value {
                containsUser = event.containsPlayer(player)
            } else {
                containsUser = false
            }
            let join = !containsUser
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
