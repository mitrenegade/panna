//
//  VenueEditViewController.swift
//  Panna
//
//  Created by Bobby Ren on 3/2/20.
//  Copyright © 2020 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class VenueEditViewController: UIViewController {

    @IBOutlet weak var photoView: RAImageView!
    @IBOutlet weak var inputName: UITextField!
    @IBOutlet weak var buttonAddPhoto: UIButton?
    var venue: Venue?

    override func viewDidLoad() {
        super.viewDidLoad()
        if let venue = venue {
            inputName.text = venue.name
            
            if let url = venue.photoUrl {
                photoView?.imageUrl = url
                buttonAddPhoto?.isHidden = true
            } else {
                photoView?.imageUrl = nil
                buttonAddPhoto?.isHidden = false
            }
        }
    }
    
    @IBAction func didClickButton(_ sender: Any) {
        
    }
}
