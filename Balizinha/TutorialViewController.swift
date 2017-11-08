//
//  TutorialViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 11/7/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

protocol TutorialDelegate: class {
    func didTapTutorial()
    func didClickNext()
}

class TutorialViewController: UIViewController {
    
    @IBOutlet weak var viewBackground: UIView!
    @IBOutlet weak var viewContent: UIView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelSubtitle: UILabel!
    @IBOutlet weak var labelDetails: UILabel!
    
    weak var delegate: TutorialDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func handleGesture(_ gesture: UIGestureRecognizer) {
        print("tapped")
        delegate?.didTapTutorial()
    }
    
    @IBAction func didClickButton(_ sender: UIButton) {
        delegate?.didClickNext()
    }
}
