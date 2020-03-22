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

protocol VenueDetailsDelegate {
    func didFinishUpdatingVenue(_ venue: Venue?)
}

class VenueDetailsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
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
    
    fileprivate let activityOverlay: ActivityIndicatorOverlay = ActivityIndicatorOverlay()

    // camera
    let cameraHelper = CameraHelper()
    
    var delegate: VenueDetailsDelegate?
    var tableManager: VenueDetailsTableManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraHelper.delegate = self

        view.addSubview(activityOverlay)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(didClickSave(_:)))
        
        tableManager = VenueDetailsTableManager(venue: existingVenue)
        tableManager?.delegate = self
        tableView.dataSource = tableManager
        tableView.delegate = tableManager
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        activityOverlay.setup(frame: view.frame)
    }

    @objc func didClickSave(_ sender: Any?) {
        if let text = tableManager?.inputName?.text {
            name = text
        }
        view.endEditing(true)
        
        navigationItem.rightBarButtonItem?.isEnabled = false

        activityOverlay.show()
        if let venue = existingVenue {
            venue.name = name
            venue.street = street
            venue.city = city
            venue.state = state
            venue.lat = lat
            venue.lon = lon
            if let photo = selectedPhoto {
                uploadPhoto(photo, for: venue) { [weak self] url in
                    venue.photoUrl = url
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                        self?.activityOverlay.hide()
//                    self.tableManager?.venue = venue // TODO: Does this need to be set too
                        self?.delegate?.didFinishUpdatingVenue(venue)
                    }
                }
            } else {
                activityOverlay.hide()
                delegate?.didFinishUpdatingVenue(venue)
                navigationItem.rightBarButtonItem?.isEnabled = true
            }
        } else {
            // create venue
            // TODO: check if venue exists within some distance.
            // TODO: if new venue, create a venue and add venueId to the event
            guard let player = PlayerService.shared.current.value else { return }
            activityOverlay.show()
            VenueService.shared.createVenue(userId: player.id, type:.unknown, name: name, street: street, city: city, state: state, lat: lat, lon: lon, placeId: nil) { [weak self] (venue, error) in
                guard let venue = venue else {
                    self?.simpleAlert("Could not select venue", defaultMessage: "There was an error creating a venue", error: error as NSError?)
                    self?.activityOverlay.hide()
                    self?.navigationItem.rightBarButtonItem?.isEnabled = true
                    return
                }
                if let photo = self?.selectedPhoto {
                    self?.uploadPhoto(photo, for: venue) { url in
                        venue.photoUrl = url
                        DispatchQueue.main.async {
                            self?.activityOverlay.hide()
                            self?.tableView.reloadData()
                            self?.navigationItem.rightBarButtonItem?.isEnabled = true
                            self?.delegate?.didFinishUpdatingVenue(venue)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                        self?.activityOverlay.hide()
                        self?.navigationItem.rightBarButtonItem?.isEnabled = true
                        self?.delegate?.didFinishUpdatingVenue(venue)
                    }
                }
            }
        }
    }
    
    func uploadPhoto(_ photo: UIImage, for venue: Venue, completion:@escaping ((String?)->Void)) {
        let alert = UIAlertController(title: "Uploading photo", message: "Upload progress: 0%", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel) { (action) in
        })
        self.present(alert, animated: true)

        FirebaseImageService.uploadImage(image: photo, type: .venue, uid: venue.id, progressHandler: { (percent) in
            alert.message = "Upload progress: \(Int(percent*100))%"
        }) { (url) in
            // dismiss
            alert.dismiss(animated: true) {
                completion(url)
            }
        }

    }
}

// MARK: VenueDetailsTableManagerDelegate
extension VenueDetailsViewController: VenueDetailsTableManagerDelegate {
    func selectPhoto() {
        view.endEditing(true)
        cameraHelper.takeOrSelectPhoto(from: self, fromView: buttonAddPhoto, frontFacing: false)
    }
}

// MARK: Camera
extension VenueDetailsViewController: CameraHelperDelegate {
    func didCancelSelection() {
        // did not make a choice on the alert. does not need any action
    }
    
    func didCancelPicker() {
        // did not pick a photo from the presented picker, which needs to be dismissed
        dismiss(animated: true, completion: nil)
    }
    
    func didSelectPhoto(selected: UIImage?) {
        guard let image = selected else { return }
        let width = self.view.frame.size.width
        let height = width / image.size.width * image.size.height
        let size = CGSize(width: width, height: height)
        let resized = FirebaseImageService.resizeImage(image: image, newSize: size)
        selectedPhoto = resized
        tableView.reloadData()
        dismiss(animated: true, completion: nil)
    }
}
