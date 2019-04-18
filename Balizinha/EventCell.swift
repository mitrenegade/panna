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
    @IBOutlet weak var constraintButtonWidth: NSLayoutConstraint?
    
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
        let viewModel = EventCellViewModel(event: event)

        labelName.text = viewModel.titleLabel
        labelLocation.text = viewModel.placeLabel
        labelTimeDate.text = viewModel.timeDateLabel

        viewModel.getEventPhoto() { [weak self] imageUrl, image in
            self?.eventLogo.imageUrl = imageUrl
            self?.eventLogo.image = image
        }

        btnAction.setTitle(viewModel.buttonTitle, for: .normal)
        btnAction.isHidden = viewModel.buttonHidden
        btnAction.titleLabel?.font = viewModel.buttonFont
        btnAction.isEnabled = viewModel.buttonActionEnabled
        btnAction.alpha = viewModel.buttonActionEnabled ? 1 : 0.5
        
        labelFull.text = viewModel.labelFullText
        labelAttendance.text = viewModel.labelAttendanceText
        
        constraintButtonWidth?.constant = viewModel.buttonWidth
    }

    @IBAction func didTapButton(_ sender: AnyObject) {
        print("Tapped Cancel/Join")
        guard let event = self.event else { return }

        let viewModel = EventCellViewModel(event: event)
        viewModel.handleButtonTap(delegate: delegate)
    }
}
