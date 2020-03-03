//
//  VenueEditViewController.swift
//  Panna
//
//  Created by Bobby Ren on 3/2/20.
//  Copyright © 2020 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha
import RACameraHelper

class VenueEditViewController: UIViewController {

    @IBOutlet weak var photoView: RAImageView!
    @IBOutlet weak var inputName: UITextField!
    @IBOutlet weak var buttonAddPhoto: UIButton?
    var venue: Venue?
    
    var selectedPhoto: UIImage?

    // camera
    let cameraHelper = CameraHelper()

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let venue = venue else { return }
        inputName.text = venue.name
        
        if let url = venue.photoUrl {
            photoView?.imageUrl = url
            buttonAddPhoto?.isHidden = true
        } else {
            photoView?.imageUrl = nil
            buttonAddPhoto?.isHidden = false
        }
        cameraHelper.delegate = self
    }
    
    @IBAction func didClickButton(_ sender: Any) {
        cameraHelper.takeOrSelectPhoto(from: self, fromView: buttonAddPhoto)
    }
}

// MARK: Camera
extension VenueEditViewController: CameraHelperDelegate {
    func didCancelSelection() {
        print("Did not edit image")
        dismiss(animated: true, completion: nil)
    }
    
    func didCancelPicker() {
        print("Did not select image")
        dismiss(animated: true, completion: nil)
    }
    
    func didSelectPhoto(selected: UIImage?) {
        guard let image = selected else { return }
        let width = self.view.frame.size.width
        let height = width / image.size.width * image.size.height
        let size = CGSize(width: width, height: height)
        let resized = FirebaseImageService.resizeImage(image: image, newSize: size)
        buttonAddPhoto?.setImage(resized, for: .normal)
        selectedPhoto = selected
        dismiss(animated: true, completion: nil)
    }
}
