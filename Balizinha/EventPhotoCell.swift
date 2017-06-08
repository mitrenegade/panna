//
//  EventPhotoCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/17/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import AsyncImageView

class EventPhotoCell: UITableViewCell {
    
    @IBOutlet var labelText: UILabel!
    @IBOutlet var photoView: AsyncImageView!
    @IBOutlet var constraintCellHeight: NSLayoutConstraint!
    @IBOutlet weak var imagePlus: UIImageView!
    
    var photo: UIImage? {
        didSet {
            if let image = self.photo {
                self.constraintCellHeight.constant = 200
                self.photoView.image = image
                UIView.animate(withDuration: 0.25, animations: {
                    self.photoView.alpha = 1
                })
                self.imagePlus.isHidden = true
            }
            else {
                self.clearPhoto()
                self.imagePlus.isHidden = false
            }
        }
    }
    
    var url: String? {
        didSet {
            if let url = url {
                self.constraintCellHeight.constant = 200
                self.photoView.imageURL = URL(string: url)
                UIView.animate(withDuration: 0.25, animations: {
                    self.photoView.alpha = 1
                })
            }
            else {
                self.clearPhoto()
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.clearPhoto()
    }
    
    func clearPhoto() {
        self.constraintCellHeight.constant = 44
        self.photoView.imageURL = nil
        self.photoView.image = nil
        self.photoView.alpha = 0
    }
}
