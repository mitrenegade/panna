//
//  ActionCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/8/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class ActionCell: UITableViewCell {
    
    @IBOutlet weak var labelText: UILabel!
    @IBOutlet weak var labelDate: UILabel?
    @IBOutlet weak var photoView: RAImageView?

    @IBOutlet weak var constraintLabelHeight: NSLayoutConstraint!
    var objectId: String?
    
    func configure(action: Action) {
        labelText.text = ActionViewModel(action: action).displayString
        labelText.sizeToFit()
        self.constraintLabelHeight.constant = max(40, labelText.frame.size.height)
        
        guard let userId = action.userId else { return }
        
        let objectId = action.id
        self.objectId = objectId
        self.refreshPhoto(userId: userId, currentId: objectId)
        
        labelDate?.text = action.createdAt?.dateString()
        
        if !action.visible {
            self.contentView.alpha = 0.25
        } else {
            self.contentView.alpha = 1
        }
    }
    
    func refreshPhoto(userId: String, currentId: String) {
        guard let photoView = self.photoView else { return }
        photoView.layer.cornerRadius = photoView.frame.size.width / 4
        photoView.clipsToBounds = true
        photoView.contentMode = .scaleAspectFill
        FirebaseImageService().profileUrl(with: userId) { (url) in
            DispatchQueue.main.async {
                if let urlString = url?.absoluteString, self.objectId == currentId  {
                    photoView.imageUrl = urlString
                }
                else {
                    photoView.imageUrl = nil
                    photoView.image = UIImage(named: "profile-img")
                }
            }
        }
    }
}
