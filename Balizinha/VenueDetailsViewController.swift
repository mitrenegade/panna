//
//  VenueDetailsViewController.swift
//  Panna
//
//  Created by Bobby Ren on 3/2/20.
//  Copyright © 2020 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha
import RACameraHelper

class VenueDetailsViewController: UIViewController {

    @IBOutlet weak var photoView: RAImageView!
    @IBOutlet weak var inputName: UITextField!
    @IBOutlet weak var buttonAddPhoto: UIButton?
    var existingVenue: Venue? // nil if new venue
    
    // TODO: only name should be settable. how to prevent others from being changed?
    var name: String?
    var street: String?
    var city: String?
    var state: String?
    var lat: Double?
    var lon: Double?

    var selectedPhoto: UIImage?

    // camera
    let cameraHelper = CameraHelper()

    override func viewDidLoad() {
        super.viewDidLoad()
        inputName.text = existingVenue?.name ?? name
        
        refreshPhoto()
        cameraHelper.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(didClickSave(_:)))
    }
    
    @IBAction func didClickButton(_ sender: Any) {
        cameraHelper.takeOrSelectPhoto(from: self, fromView: buttonAddPhoto)
    }
    
    func refreshPhoto() {
        if let url = existingVenue?.photoUrl {
            photoView?.imageUrl = url
        } else if let photo = selectedPhoto {
            photoView?.image = photo
        } else {
            photoView?.imageUrl = nil
        }
    }
    
    @objc func didClickSave(_ sender: Any?) {
        if let venue = existingVenue {
            venue.name = inputName?.text
            venue.street = street
            venue.city = city
            venue.state = state
            venue.lat = lat
            venue.lon = lon
            if let photo = selectedPhoto {
                uploadPhoto(photo, for: venue) { url in
                    venue.photoUrl = url
                    self.refreshPhoto()
                }
            }
        } else {
            // create venue
            // TODO: check if venue exists within some distance.
            // TODO: if new venue, create a venue and add venueId to the event
            guard let player = PlayerService.shared.current.value else { return }
            // TODO
//                activityOverlay.show()
            VenueService.shared.createVenue(userId: player.id, type:.unknown, name: name, street: street, city: city, state: state, lat: lat, lon: lon, placeId: nil) { [weak self] (venue, error) in
                guard let venue = venue else {
                    self?.simpleAlert("Could not select venue", defaultMessage: "There was an error creating a venue", error: error as? NSError)
                    return
                }
                if let photo = self?.selectedPhoto {
                    self?.uploadPhoto(photo, for: venue) { url in
                        venue.photoUrl = url
                        DispatchQueue.main.async {
                            self?.refreshPhoto()
                            // TODO
//                                self?.activityOverlay.hide()
//                                self?.delegate.didSelect(venue: venue)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.refreshPhoto()
                        // TODO
//                            self?.activityOverlay.hide()
//                            self?.delegate.didSelect(venue: venue)
                    }
                }
            }
        }
    }
    
    func uploadPhoto(_ photo: UIImage, for venue: Venue, completion:@escaping ((String?)->Void)) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel) { (action) in
        })

        FirebaseImageService.uploadImage(image: photo, type: .venue, uid: venue.id, progressHandler: { (percent) in
            alert.title = "Upload progress: \(Int(percent*100))%"
        }) { (url) in
            // dismiss
            alert.dismiss(animated: true) {
                completion(url)
            }
        }

    }
}

// MARK: Camera
extension VenueDetailsViewController: CameraHelperDelegate {
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
