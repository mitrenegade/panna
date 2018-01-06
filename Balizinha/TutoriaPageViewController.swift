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
    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.layer.cornerRadius = imageView.frame.size.width / 2
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        imageView.layer.cornerRadius = imageView.frame.size.width / 2
    }
}
