//
//  VenueCell.swift
//  Panna
//
//  Created by Bobby Ren on 8/22/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

protocol VenueCellDelegate {
    func didClickMap(_ venue: Venue)
    func didClickEdit(_ venue: Venue)
}

class VenueCell: UITableViewCell {
    @IBOutlet weak var photoView: RAImageView?
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var buttonMap: UIButton?
    @IBOutlet weak var buttonEdit: UIButton?

    var venue: Venue?
    weak var presenter: UIViewController?
    var delegate: VenueCellDelegate?

    func configure(with venue: Venue?) {
        guard let venue = venue else { return }
        self.venue = venue
        nameLabel.text = venue.name
        addressLabel.text = venue.shortString
        typeLabel.text = venue.typeString
        if venue.isRemote {
            typeLabel.isHidden = true
        }
        
        if let url = venue.photoUrl {
            photoView?.imageUrl = url
            photoView?.isHidden = false
        } else {
            photoView?.isHidden = true
        }
        if venue.lat == nil || venue.lon == nil {
            buttonMap?.isHidden = true
        }
    }
    
    @IBAction func didClickMap(_ sender: UIButton?) {
        guard let venue = venue else { return }
        delegate?.didClickMap(venue)
    }
    
    @IBAction func didClickEdit(_ sender: UIButton?) {
        guard let venue = venue else { return }
        delegate?.didClickEdit(venue)
    }
}

