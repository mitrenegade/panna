//
//  TutoriaPageViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 11/20/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

class TutoriaPageViewController: UIViewController {
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelSubtitle: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // this forces the imageView to be the correct width by the time containerView changes size due to autolayout. Otherwise, imageView doesn't get the update until the next layout
        containerView.setNeedsUpdateConstraints()
        containerView.layoutIfNeeded()
        imageView.layer.cornerRadius = imageView.frame.size.width / 2
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        imageView.layer.cornerRadius = imageView.frame.size.width / 2
    }
}
