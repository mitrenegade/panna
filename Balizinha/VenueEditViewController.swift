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
    var venue: Venue? // nil if new venue
    
    var selectedPhoto: UIImage?

    // camera
    let cameraHelper = CameraHelper()

    override func viewDidLoad() {
        super.viewDidLoad()
        inputName.text = venue?.name
        
        refreshPhoto()
        cameraHelper.delegate = self
    }
    
    @IBAction func didClickButton(_ sender: Any) {
        cameraHelper.takeOrSelectPhoto(from: self, fromView: buttonAddPhoto)
    }
    
    func refreshPhoto() {
        if let url = venue?.photoUrl {
            photoView?.imageUrl = url
        } else if let photo = selectedPhoto {
            photoView?.image = photo
        } else {
            photoView?.imageUrl = nil
        }
    }
    
    func save() {
        if let venue = venue, let photo = selectedPhoto {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close", style: .cancel) { (action) in
            })

            FirebaseImageService.uploadImage(image: photo, type: .venue, uid: venue.id, progressHandler: { (percent) in
                alert.title = "Upload progress: \(Int(percent*100))%"
            }) { [weak self] (url) in
                if let url = url {
                    venue.photoUrl = url
                    self?.refreshPhoto()
                }
                // dismiss
                alert.dismiss(animated: true) {
                    self?.dismiss(animated: true, completion: nil)
                }
            }
        } else {
            // TODO: save name and photo to a created venue
        }
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
        selectedPhoto = resized
        refreshPhoto()
        dismiss(animated: true, completion: nil)
    }
}
