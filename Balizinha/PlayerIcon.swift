//
//  PlayerIcon.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/19/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import AsyncImageView

var iconSize: CGFloat = 30
class PlayerIcon: NSObject {
    var view: UIView! = UIView()
    var imageView: AsyncImageView = AsyncImageView()
    var player: Player? {
        didSet {
            // FIXME: imageView must be explicitly sized, and cannot just be the same size is view
            imageView.frame = CGRect(x: 0, y: 0, width: iconSize, height: iconSize)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = imageView.frame.size.height / 4
            
            self.refreshPhoto(url: player?.photoUrl)
            
            if imageView.superview == nil {
                self.view.addSubview(imageView)
            }
            
        }
    }
    
    func refreshPhoto(url: String?) {
        if let url = url, let URL = URL(string: url) {
            self.imageView.imageURL = URL
        }
        else {
            self.imageView.imageURL = nil
            self.imageView.image = UIImage(named: "profile-img")
        }
    }
    
    func remove() {
        self.view.removeFromSuperview()
    }
}

