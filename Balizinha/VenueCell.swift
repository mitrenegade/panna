//
//  VenueCell.swift
//  Panna
//
//  Created by Bobby Ren on 8/22/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class VenueCell: UITableViewCell {
    @IBOutlet weak var photoView: RAImageView?
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var buttonMap: UIButton?
    
    var venue: Venue?
    weak var presenter: UIViewController?

    func configure(with venue: Venue?) {
        guard let venue = venue else { return }
        self.venue = venue
        nameLabel.text = venue.name
        addressLabel.text = venue.shortString ?? nil
        
        // TODO: load venue image
        if let url = venue.photoUrl {
            photoView?.imageUrl = url
        } else {
            photoView?.isHidden = true
        }
        if venue.lat == nil || venue.lon == nil {
            buttonMap?.isHidden = true
        }
    }
    
    @IBAction func didClickMap(_ sender: UIButton?) {
        MapService.goToMapLocation(venue: venue)
    }
}

