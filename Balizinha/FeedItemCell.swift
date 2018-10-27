//
//  FeedItemCell.swift
//  Panna
//
//  Created by Bobby Ren on 10/3/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class FeedItemCell: ActionCell {
    @IBOutlet weak var feedItemPhotoView: RAImageView?
    @IBOutlet weak var constraintWidth: NSLayoutConstraint?
    @IBOutlet weak var labelDetails: UILabel?

    func configure(with feedItem: FeedItem) {
        if let message = feedItem.message, !message.isEmpty {
            labelText.text = message
            if feedItem.type == .chat, let userId = feedItem.userId {
                PlayerService.shared.withId(id: userId, completion: { [weak self] (player) in
                    if let name = player?.name {
                        DispatchQueue.main.async {
                            self?.labelText.text = "\(name) said: \(message)"
                        }
                    }
                })
            }
        } else {
            labelText.text = feedItem.defaultMessage
        }
        
        if let actionId = feedItem.actionId {
            ActionService().withId(id: actionId) { [weak self] (action) in
                if let action = action {
                    let viewModel = ActionViewModel(action: action)
                    let eventName = viewModel.eventName
                    
                    self?.labelDetails?.text = eventName
                }
            }
        }
        labelText.sizeToFit()
        constraintLabelHeight.constant = max(27, self.labelText.frame.size.height)

        // load user profile
        guard let userId = feedItem.userId else { return }
        let objectId = feedItem.id
        self.objectId = objectId
        refreshPhoto(userId: userId, currentId: objectId)
        
        // load image
        if feedItem.hasPhoto, feedItemPhotoView != nil {
            refreshFeedItemPhoto(feedItemId: feedItem.id, currentId: objectId)
            constraintWidth?.constant = self.frame.size.width
        }
    }
    
    fileprivate func refreshFeedItemPhoto(feedItemId: String, currentId: String) {
        FirebaseImageService().feedItemPhotoUrl(with: feedItemId) {[weak self] (url) in
            DispatchQueue.main.async {
                if let urlString = url?.absoluteString, self?.objectId == currentId {
                    self?.feedItemPhotoView?.imageUrl = urlString
                } else {
                    self?.feedItemPhotoView?.imageUrl = nil
                    self?.feedItemPhotoView?.image = nil
                }
            }
        }
    }
}
