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
    @IBOutlet weak var photoView: UIImageView?
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
    }
    
    @IBAction func didClickMap(_ sender: UIButton?) {
        // TODO: open google map to show location
    }
}

