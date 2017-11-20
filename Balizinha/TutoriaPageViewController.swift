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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        imageView.layer.cornerRadius = imageView.frame.size.width / 2
    }
}
