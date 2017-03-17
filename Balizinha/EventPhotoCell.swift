//
//  EventPhotoCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/17/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

class EventPhotoCell: UITableViewCell {
    
    @IBOutlet var labelText: UILabel!
    @IBOutlet var photoView: UIImageView!
    @IBOutlet var constraintCellHeight: NSLayoutConstraint!
    
    var photo: UIImage? {
        didSet {
            self.refreshPhoto()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.refreshPhoto()
    }
    
    func refreshPhoto() {
        if let image = self.photo {
            self.constraintCellHeight.constant = 200
            self.photoView.image = image
            UIView.animate(withDuration: 0.25, animations: {
                self.photoView.alpha = 1
            })
        }
        else {
            self.clearPhoto()
        }
    }
    
    func clearPhoto() {
        self.constraintCellHeight.constant = 44
        self.photoView.alpha = 0
    }
}
