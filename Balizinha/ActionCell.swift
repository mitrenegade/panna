//
//  ActionCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/8/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import AsyncImageView

class ActionCell: UITableViewCell {
    
    @IBOutlet var labelText: UILabel!
    @IBOutlet var photoView: AsyncImageView?
    @IBOutlet var constraintLabelHeight: NSLayoutConstraint!
    var actionId: String?

    func configureWith(action: Action) {
        self.labelText.text = action.displayString
        self.labelText.sizeToFit()
        self.constraintLabelHeight.constant = max(40, self.labelText.frame.size.height)
        
        guard let userId = action.user else { return }
        
        let actionId = action.id
        self.actionId = actionId
        PlayerService.shared.withId(id: userId) { (player) in
            print("url: \(String(describing: player?.photoUrl))")
            if let url = player?.photoUrl {
                self.refreshPhoto(url: url, currentActionId: actionId)
            }
            else {
                self.refreshPhoto(url: nil, currentActionId: actionId)
            }
        }

    }
    
    func refreshPhoto(url: String?, currentActionId: String) {
        guard let photoView = self.photoView else { return }
        photoView.layer.cornerRadius = photoView.frame.size.width / 4
        photoView.clipsToBounds = true
        photoView.contentMode = .scaleAspectFill
        if let url = url, let URL = URL(string: url), self.actionId == currentActionId  {
            photoView.imageURL = URL
        }
        else {
            photoView.imageURL = nil
            photoView.image = UIImage(named: "profile-img")
        }
    }

}
