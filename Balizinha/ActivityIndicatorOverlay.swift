//
//  ActivityIndicatorOverlay.swift
//  Balizinha
//
//  Created by Bobby Ren on 7/26/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class ActivityIndicatorOverlay: UIView {
    var activityIndicator: UIActivityIndicatorView?
    func setup(frame: CGRect) {
        self.frame = frame
        
        if activityIndicator == nil {
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
            activityIndicator.hidesWhenStopped = false
            activityIndicator.startAnimating()
            activityIndicator.color = UIColor.red
            addSubview(activityIndicator)
            self.activityIndicator = activityIndicator
        }
        activityIndicator?.center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)

        backgroundColor = UIColor(white: 0, alpha: 0.5)
        isHidden = true
    }
    
    func show() {
        isHidden = false
    }
    
    func hide() {
        isHidden = true
    }
}
