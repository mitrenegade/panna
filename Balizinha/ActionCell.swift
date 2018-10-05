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
    
    @IBOutlet var labelText: UILabel!
    @IBOutlet var photoView: RAImageView?
    @IBOutlet var constraintLabelHeight: NSLayoutConstraint!
    var objectId: String?

    func configureWith(action: Action) {
        let viewModel = ActionViewModel(action: action)
        self.labelText.text = viewModel.displayString
        self.labelText.sizeToFit()
        self.constraintLabelHeight.constant = max(40, self.labelText.frame.size.height)
        
        guard let userId = action.userId else { return }
        
        let objectId = action.id
        self.objectId = objectId
        self.refreshPhoto(userId: userId, currentId: objectId)
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
