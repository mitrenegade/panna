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

    func configure(with feedItem: FeedItem) {
        
        self.labelText.text = feedItem.message ?? feedItem.defaultMessage
        self.labelText.sizeToFit()
        self.constraintLabelHeight.constant = max(40, self.labelText.frame.size.height)
        
        // load user profile
        guard let userId = feedItem.userId else { return }
        let objectId = feedItem.id
        self.objectId = objectId
        self.refreshPhoto(userId: userId, currentId: objectId)
        
        // load image
        if feedItem.hasPhoto, feedItemPhotoView != nil {
            refreshFeedItemPhoto(feedItemId: feedItem.id, currentId: objectId)
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
