//
//  FirebaseModelIcon.swift
//  Balizinha
//
//  Created by Bobby Ren on 4/21/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class FirebaseModelIcon: UIView {
    var imageView: RAImageView = RAImageView()

    var object: FirebaseBaseModel? {
        didSet {
            refresh()
        }
    }
    
    internal var photoUrl: String? {
        return nil
    }
    
    fileprivate func refreshPhoto(url: String?) {
        imageView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        if let url = url {
            imageView.imageUrl = url
        }
        else {
            imageView.imageUrl = nil
            imageView.image = UIImage(named: "profile-img")
        }
    }
    
    func refresh() {
        // FIXME: imageView must be explicitly sized, and cannot just be the same size is view
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = imageView.frame.size.height / 4
        
        refreshPhoto(url: photoUrl)
        
        if imageView.superview == nil {
            self.addSubview(imageView)
        }
    }
    
    func remove() {
        removeFromSuperview()
    }
}
