//
//  PlayerCell.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 2/3/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import Balizinha

class PlayerCell: UITableViewCell {
    @IBOutlet weak var imagePhoto: RAImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelId: UILabel?
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var labelDetails: UILabel!
    
    // photo constraints
    @IBOutlet weak var constraintImageWidth: NSLayoutConstraint!
    @IBOutlet weak var constraintNameLeftOffset: NSLayoutConstraint!
    @IBOutlet weak var constraintNameTopOffset: NSLayoutConstraint!
    
    // detail constraints
    @IBOutlet weak var constraintDetailHeight: NSLayoutConstraint!

    func configure(player: Player, expanded: Bool) {
        labelName.text = player.name ?? player.email ?? "Anon"
        labelId?.text = player.id
        labelDate.text = player.createdAt?.dateString()

        FirebaseImageService().profileUrl(with: player.id) {[weak self] (url) in
            DispatchQueue.main.async {
                if let weakself = self, let urlString = url?.absoluteString {
                    weakself.updatePhoto(urlString: urlString)
                    
                    if expanded {
                        weakself.constraintImageWidth.constant = weakself.frame.size.width - 30
                        weakself.constraintNameLeftOffset.constant = 15
                        weakself.constraintNameTopOffset.constant = weakself.frame.size.width - 30
                        
                    } else {
                        weakself.constraintImageWidth.constant = 50
                        weakself.constraintNameLeftOffset.constant = 15 + 50 + 8
                        weakself.constraintNameTopOffset.constant = 0
                    }
                } else {
                    self?.constraintImageWidth.constant = 0
                    self?.constraintNameLeftOffset.constant = 15
                    self?.constraintNameTopOffset.constant = 0
                }
            }
        }
        
        if player.id == "oWNfx7Z4M9QVlOMfPJyH6hf8fh33" {
            print("Here")
        }
        
        var detailText: String = ""
        if let email = player.email {
            detailText = detailText + "Email: \(email)\n"
        }
        if let city = player.city {
            detailText = detailText + "City: \(city)\n"
        }
        if let info = player.info {
            detailText = detailText + "Info: \(info)\n"
        }
        if let lat = player.lat, let lon = player.lon, let active = player.lastLocationTimestamp {
            let time = active.dateString()
            detailText = detailText + "Location: \(lat), \(lon)\nActive: \(time)"
        }
        labelDetails.text = detailText
        let bounds = (detailText as NSString).size(withAttributes: [NSAttributedStringKey.font: labelDetails.font])
        if expanded {
            constraintDetailHeight.constant = bounds.height + 50
        } else {
            constraintDetailHeight.constant = 0
        }
    }
    
    func updatePhoto(urlString: String) {
        imagePhoto.image = nil
        imagePhoto.imageUrl = urlString
    }
    
    func reset() {
        labelName.text = nil
        labelId.text = nil
        labelDate.text = nil
    }
}
