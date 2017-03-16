//
//  ActionCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/8/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

class ActionCell: UITableViewCell {
    
    @IBOutlet var labelText: UILabel!
    @IBOutlet var photoView: UIImageView!
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
            print("url: \(player?.photoUrl)")
            if let url = player?.photoUrl {
                self.refreshPhoto(url: url, currentActionId: actionId)
            }
            else {
                self.refreshPhoto(url: nil, currentActionId: actionId)
            }
        }

    }
    
    func refreshPhoto(url: String?, currentActionId: String) {
        self.photoView.layer.cornerRadius = self.photoView.frame.size.width / 4
        self.photoView.clipsToBounds = true
        do {
            if let url = url, let URL = URL(string: url) {
                let data = try Data(contentsOf: URL)
                if let image = UIImage(data: data), self.actionId == currentActionId {
                    // only set if the cell is still for the same actionId
                    self.photoView.image = image
                }
            }
            else {
                self.photoView.image = UIImage(named: "profile-img")
            }
        }
        catch {
            print("invalid photo")
        }
    }

}
