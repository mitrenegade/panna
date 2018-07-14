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
    
    internal func photoUrl(id: String?, completion: @escaping ((URL?)->Void)) {
        completion(nil)
    }
    
    fileprivate func refreshPhoto() {
        imageView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = imageView.frame.size.height / 4
        imageView.contentMode = .scaleAspectFill
        photoUrl(id: object?.id) { (url) in
            if let urlString = url?.absoluteString {
                self.imageView.imageUrl = urlString
            }
            else {
                self.imageView.imageUrl = nil
                self.imageView.image = UIImage(named: "profile-img")
            }
        }
    }
    
    func refresh() {
        if imageView.superview == nil {
            self.addSubview(imageView)
        }
        refreshPhoto()
    }
    
    func remove() {
        removeFromSuperview()
    }
}
