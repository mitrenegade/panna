//
//  PlayerInfoViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 2/4/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

protocol PlayerDelegate: class {
    func didUpdatePlayer(player: Player)
}

class PlayerInfoViewController: UIViewController {
    
    @IBOutlet weak var buttonPhoto: UIButton!
    @IBOutlet weak var inputName: UITextField!
    @IBOutlet weak var inputCity: UITextField!
    var inputState: UITextField? // from state selection alert
    @IBOutlet weak var inputNotes: UITextView!
    @IBOutlet weak var photoView: RAImageView!
    @IBOutlet weak var buttonLeague: UIButton!
    
    // home venue
    fileprivate var currentVenue: Venue?
    @IBOutlet weak var containerVenue: UIView?
    @IBOutlet weak var labelVenueName: UILabel?
    @IBOutlet weak var labelVenueAddress: UILabel?
    @IBOutlet weak var venueImageView: RAImageView?
    
    @IBOutlet weak var containerAddVenue: UIView?
    @IBOutlet weak var buttonAddVenue: UIButton?

    var cityHelper: CityHelper?
    
    weak var currentInput: UITextField?
    var player: Player?
    weak var delegate: PlayerDelegate?
    var isCreatingPlayer = false
    
    fileprivate var askedForPhoto = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        inputNotes.text = nil
        
        if self.isCreatingPlayer {
            self.title = "New player"
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil) // hide back button
        }
        else {
            self.title = "Edit profile"
            self.navigationItem.rightBarButtonItem = nil
        }
        
        refresh()
        
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = PannaUI.navBarTint
        
        photoView.image = UIImage(named: "profile-img")?.withRenderingMode(.alwaysTemplate)
        photoView.tintColor = PannaUI.profileTint

        cityHelper = CityHelper(inputField: inputCity, delegate: self)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapVenue(_:)))
        containerVenue?.addGestureRecognizer(tap)
    }

    func refresh() {
        guard let player = player else { return }
        
        if let name = player.name {
            inputName.text = name
        }
        if let cityId = player.cityId {
            CityService.shared.withId(id: cityId) { [weak self] (city) in
                DispatchQueue.main.async {
                    if let city = city as? City {
                        self?.inputCity.text = city.shortString
                    }
                }
            }
        }
        if let notes = player.info {
            inputNotes.text = notes
        }
        refreshPhoto()
        refreshVenueOptions()
    }
    
    func refreshPhoto() {
        photoView.layer.cornerRadius = photoView.frame.size.width / 2
        FirebaseImageService().profileUrl(with: player?.id) { [weak self] (url) in
            DispatchQueue.main.async {
                if let url = url {
                    self?.photoView.image = nil
                    self?.photoView.imageUrl = url.absoluteString
                    self?.buttonPhoto.setTitle("Update Photo", for: .normal)
                } else {
                    self?.photoView.layer.cornerRadius = 0
                    self?.photoView.image = UIImage(named: "profile-img")?.withRenderingMode(.alwaysTemplate)
                    self?.photoView.tintColor = PannaUI.profileTint
                    self?.buttonPhoto.setTitle("Add Photo", for: .normal)
                }
            }
        }
    }
    
    func refreshVenueOptions() {
        if let venue = currentVenue {
            containerVenue?.isHidden = false
            containerAddVenue?.isHidden = true
            refreshVenue(venue)
        } else {
            containerVenue?.isHidden = true
            containerAddVenue?.isHidden = false
            guard let venueId = player?.baseVenueId else {
                buttonAddVenue?.setTitle("Click to select home venue", for: .normal)
                return
            }
            buttonAddVenue?.setTitle("Loading...", for: .normal)
            VenueService.shared.withId(id: venueId) { [weak self] (venue) in
                if let venue = venue as? Venue {
                    self?.containerVenue?.isHidden = false
                    self?.containerAddVenue?.isHidden = true
                    self?.currentVenue = venue
                    self?.refreshVenue(venue)
                } else {
                    self?.containerVenue?.isHidden = true
                    self?.containerAddVenue?.isHidden = false
                    self?.buttonAddVenue?.setTitle("Click to select home venue", for: .normal)
                }
            }
        }
    }
    
    func refreshVenue(_ venue: Venue) {
        labelVenueName?.text = venue.name
        labelVenueAddress?.text = venue.shortString
        if let url = venue.photoUrl {
            venueImageView?.imageUrl = url
            venueImageView?.isHidden = false
        } else {
            venueImageView?.isHidden = true
        }
    }
    
    @objc @IBAction func didTapVenue(_ sender: Any) {
        performSegue(withIdentifier: "toVenues", sender: sender)
    }
    
    func close() {
        if self.isCreatingPlayer {
            // on signup, don't pop or dismiss
            if self.player?.photoUrl == nil && !askedForPhoto {
                promptForPhotoOnce()
                return
            }
            
            print("LoginLogout: LoginSuccess from sign up")
        }
        
        if let player = player {
            self.delegate?.didUpdatePlayer(player: player)
        }
        
        if self.navigationController?.viewControllers[0] == self {
            self.navigationController?.dismiss(animated: true, completion: {
            })
        }
        else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    @IBAction func didClickAddPhoto(_ sender: AnyObject?) {
        self.view.endEditing(true)
        let alert = UIAlertController(title: "Select image", message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action) in
                self.selectPhoto(camera: true)
            }))
        }
        alert.addAction(UIAlertAction(title: "Photo album", style: .default, handler: { (action) in
            self.selectPhoto(camera: false)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action) in
        })
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad)
        {
            alert.popoverPresentationController?.sourceView = self.view
            alert.popoverPresentationController?.sourceRect = buttonPhoto.frame
        }
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func didClickSave(_ sender: AnyObject?) {
        self.view.endEditing(true)

        guard let player = self.player else {
            close()
            return
        }
        
        if let text = self.inputName.text, text.count > 0 {
            player.name = text
        }
        else if isCreatingPlayer {
            self.simpleAlert("Please enter a name", message: "Our players would like to know what to call you.")
            return
        }
        
        if let text = inputNotes.text, !text.isEmpty {
            player.info = text
        }

        close()
    }

    fileprivate func promptForPhotoOnce() {
        askedForPhoto = true
        let alert = UIAlertController(title: "Add a photo?", message: "Hey, including your picture will make it easier for the organizer and the other players to recognize you. Would you like to add a photo?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            // clicking ok cancels the save action
        }))
        alert.addAction(UIAlertAction(title: "Not now", style: .cancel) { (action) in
            self.close()
        })
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: UITextFieldDelegate
extension PlayerInfoViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        currentInput = textField
        
        if currentInput == inputCity {
            // if player's city exists
            if let cityId = player?.cityId {
                cityHelper?.currentCityId = cityId
                cityHelper?.refreshCities()
            }
            cityHelper?.showCitySelector(from: self)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: Camera
// photo
extension PlayerInfoViewController {
    override var prefersStatusBarHidden: Bool {
        return false
    }                   
    func selectPhoto(camera: Bool) {
        self.view.endEditing(true)
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true

        picker.view.backgroundColor = .blue

        if camera, UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
            picker.showsCameraControls = true
        } else {
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                picker.sourceType = .photoLibrary
            }
            else {
                picker.sourceType = .savedPhotosAlbum
            }
            picker.navigationBar.isTranslucent = false
            picker.navigationBar.barTintColor = PannaUI.navBarTint
        }

        self.present(picker, animated: true)
    }
    
    func didTakePhoto(image: UIImage) {
        guard let id = self.player?.id else {
            self.simpleAlert("Invalid info", message: "We could not save your photo because your user is invalid. Please log out and log back in.")
            return
        }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel) { (action) in
        })
        let smallerImage = FirebaseImageService.resizeImageForProfile(image: image)
        FirebaseImageService.uploadImage(image: smallerImage ?? image, type: .player, uid: id, progressHandler: { (percent) in
            alert.title = "Upload progress: \(Int(percent*100))%"
        }) { (url) in
            if let url = url {
                self.refreshPhoto()
                if let player = PlayerService.shared.current.value {
                    player.photoUrl = url // legacy apps need this url
                }
            }
            // dismiss
            alert.dismiss(animated: true, completion: nil)
        }
        self.photoView.image = image
        self.photoView.layer.cornerRadius = self.photoView.frame.size.width / 2
        
        self.dismissCamera {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func dismissCamera(completion: (()->Void)? = nil) {
        self.dismiss(animated: true, completion: completion)
    }
}

extension PlayerInfoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let img = info[UIImagePickerController.InfoKey.editedImage] ?? info[UIImagePickerController.InfoKey.originalImage]
        guard let photo = img as? UIImage else { return }
        self.didTakePhoto(image: photo)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismissCamera()
    }
    
}

extension PlayerInfoViewController: CityHelperDelegate {
    func didStartCreatingCity() {
        showLoadingIndicator()
    }

    func didSelectCity(_ city: City?) {
        DispatchQueue.main.async { [weak self] in
            self?.hideLoadingIndicator()
            if let city = city {
                PlayerService.shared.updateCityAndNotify(city: city)
                self?.inputCity.text = city.shortString
            }
        }
    }
    
    func didFailSelectCity(with error: Error?) {
        simpleAlert("Could not create city", defaultMessage: "There was an issue creating a city", error: error as NSError?)
    }
    
    func didCancelSelectCity() {
        refresh()
    }
}

// venues
extension PlayerInfoViewController: VenuesListDelegate {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toVenues" {
            let venuesController = segue.destination as? VenuesListViewController
            venuesController?.delegate = self
        }
    }

    func didCancelSelection() {
        // no op
    }

    func didSelectVenue(_ venue: Venue) {
        currentVenue = venue
        player?.baseVenueId = venue.id
        refreshVenueOptions()
        navigationController?.popToViewController(self, animated: true)
    }
    
    func didCreateVenue(_ venue: Venue) {
        currentVenue = venue
        player?.baseVenueId = venue.id
        refreshVenueOptions()
        navigationController?.popToViewController(self, animated: true)
    }
}
