//
//  EventCell.swift
// Balizinha
//
//  Created by Tom Strissel on 5/18/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

protocol EventCellDelegate: class {
    func joinOrLeaveEvent(_ event: Balizinha.Event, join: Bool)
    func editEvent(_ event: Balizinha.Event)
    func previewEvent(_ event: Balizinha.Event)
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
    
    var event: Balizinha.Event?
    weak var delegate: EventCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.eventLogo.layer.cornerRadius = self.eventLogo.frame.size.height / 2
        self.eventLogo.layer.borderWidth = 1.0
        self.eventLogo.layer.masksToBounds = true
        self.eventLogo.contentMode = .scaleAspectFill
        
        self.btnAction.layer.cornerRadius = self.btnAction.frame.size.height / 5
    }

    func setupWithEvent(_ event: Balizinha.Event) {
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
        let viewModel = EventCellViewModel(event: event)

        if let leagueId = event.league {
            FirebaseImageService().leaguePhotoUrl(with: leagueId) { [weak self] (url) in
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
            eventLogo.imageUrl = nil
            eventLogo.image = UIImage(named: "soccer")
        }

        let title = viewModel.buttonTitle
        btnAction.setTitle(title, for: .normal)
        btnAction.isHidden = viewModel.buttonHidden
        btnAction.alpha = 1
        btnAction.titleLabel?.font = viewModel.buttonFont
        btnAction.isEnabled = viewModel.buttonActionEnabled
        
        labelFull.text = viewModel.labelFullText
        labelAttendance.text = viewModel.labelAttendanceText
    }

    @IBAction func didTapButton(_ sender: AnyObject) {
        print("Tapped Cancel/Join")
        guard let event = self.event else { return }
        guard !AuthService.isAnonymous else {
            delegate?.previewEvent(event)
            return
        }

        let viewModel = EventCellViewModel(event: event)

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
    }
}
