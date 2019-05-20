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
    @IBOutlet weak var inputNotes: UITextView!
    @IBOutlet weak var photoView: RAImageView!
    @IBOutlet weak var buttonLeague: UIButton!

    weak var currentInput: UITextField?
    var cityPickerView: UIPickerView = UIPickerView()

    var player: Player?
    weak var delegate: PlayerDelegate?
    var isCreatingPlayer = false
    
    fileprivate var askedForPhoto = false
    var service: VenueService?
    var cities: [City] = []
    
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
        
        self.setupInputs()
        self.refresh()
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = UIColor.mediumBlue
    }
    
    func setupInputs() {
        let keyboardDoneButtonView: UIToolbar = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.black
        keyboardDoneButtonView.tintColor = UIColor.white
        let cancel: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelEditing))
        let flex: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let saveButton: UIBarButtonItem = UIBarButtonItem(title: "Update", style: .done, target: self, action: #selector(save))
        keyboardDoneButtonView.setItems([cancel, flex, saveButton], animated: true)
        
        self.inputName.inputAccessoryView = keyboardDoneButtonView
        self.inputCity.inputAccessoryView = keyboardDoneButtonView
        self.inputNotes.inputAccessoryView = keyboardDoneButtonView
        
        cityPickerView.sizeToFit()
        cityPickerView.backgroundColor = .white
        cityPickerView.delegate = self
        cityPickerView.dataSource = self
        
        inputCity.inputView = cityPickerView
        
        // load cities if needed
        if AIRPLANE_MODE {
            service = MockVenueService()
        } else {
            service = VenueService.shared
        }
        if service?.cities.isEmpty ?? true {
            service?.getCities { [weak self] (cities) in
                print("loaded \(cities) cities")
                self?.cities = cities
            }
        } else {
            cities = service?.cities ?? []
        }
    }
    
    func refresh() {
        guard let player = player else { return }
        
        if let name = player.name {
            self.inputName.text = name
        }
        if let city = player.city {
            self.inputCity.text = city
        }
        if let notes = player.info {
            self.inputNotes.text = notes
        }
        self.refreshPhoto()
        refreshLeagueButton()
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
                    self?.photoView.image = UIImage(named: "profile-img")
                    self?.buttonPhoto.setTitle("Add Photo", for: .normal)
                }
            }
        }
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
        
        if let text = self.inputCity.text, !text.isEmpty {
            player.city = text
        }
        if let text = inputNotes.text, !text.isEmpty {
            player.info = text
        }

        close()
    }
    
    @objc func save() {
        self.view.endEditing(true)
        
        player?.info = self.inputNotes.text
        if currentInput == inputName, inputName.text?.isEmpty == false {
            player?.name = inputName.text
        }
        else if currentInput == inputCity, inputCity.text?.isEmpty == false {
            player?.city = inputCity.text
        }
    }

    @objc func cancelEditing() {
        self.view.endEditing(true)
        inputNotes.resignFirstResponder()
        
        inputName.text = player?.name
        inputCity.text = player?.city
        inputNotes.text = player?.info
    }
    
    fileprivate func promptForPhotoOnce() {
        askedForPhoto = true
        let alert = UIAlertController(title: "Add a photo?", message: "Hey, including your picture will make it easier for the organizer and the other players to recognize you. Would you like to add a photo?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) in
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
    func selectPhoto(camera: Bool) {
        self.view.endEditing(true)
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true

        picker.view.backgroundColor = .blue
        UIApplication.shared.isStatusBarHidden = false

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
            picker.navigationBar.barTintColor = UIColor.mediumBlue
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
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let img = info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]
        guard let photo = img as? UIImage else { return }
        self.didTakePhoto(image: photo)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismissCamera()
    }
    
}

// MARK: - Leagues
extension PlayerInfoViewController {
    func refreshLeagueButton() {
        guard let player = player else {
            buttonLeague.isHidden = true
            return
        }

//        guard let leagueId: String = player.leagues.first else {
//            buttonLeague.setTitle("Join a league", for: .normal)
//            return
//        }

//        buttonLeague.setTitle("League", for: .normal)
//        LeagueService.shared.withId(id: leagueId) {[weak self] (league) in
//            guard let league = league else {
//                DispatchQueue.main.async {
//                    self?.buttonLeague.setTitle("Invalid league", for: .normal)
//                }
//                return
//            }
//            DispatchQueue.main.async {
//                self?.buttonLeague.setTitle("Leave \(league.name ?? "")", for: .normal)
//            }
//        }
    }
    
    @IBAction func didClickLeague(_ sender: Any?) {
        // FOR TESTING
//        let leagueId = "1523416155-990463"
        let leagueId = "1523426391-995740"
        guard let player = player else { return }
        
        // test join league
        LeagueService.shared.withId(id: leagueId) { (league) in
            guard let league = league else { return }
            
            // test join league
            LeagueService.shared.join(league: league, completion: {[weak self] (result, error) in
                DispatchQueue.main.async {
                    PlayerService.shared.refreshCurrentPlayer() // todo: this happens asynchronously
                    self?.refreshLeagueButton()
                }
            })
            
            // test player for league
            LeagueService.shared.players(for: league, completion: { (results) in
                print("Players in league \(league.id): \(results)")
            })

            // test league for player
            LeagueService.shared.leagueMemberships(for: player, completion: { (results) in
                print("Leagues for player \(player.id): \(results)")
            })
        }
    }
}

extension PlayerInfoViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    //MARK: - Delegates and data sources
    //MARK: Data Sources
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return cities.count + 1
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        //print("Reloaded components")
        if row < cities.count {
            return cities[row].shortString
        }
        return "Add a city"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // let user pick more dates and click done
        if row < cities.count {
            print("Picked city \(cities[row])")
            let city = cities[row]
            player?.city = city.shortString
            player?.cityId = city.firebaseKey
            inputCity.text = city.shortString
        } else {
            print("Add a city")
            promptForNewCity()
        }
    }
}

// Creating a new city
extension PlayerInfoViewController {
    func promptForNewCity() {
        inputCity.resignFirstResponder()
        let alert = UIAlertController(title: "Please enter a city name", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Boston"
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if let textField = alert.textFields?[0], let value = textField.text, !value.isEmpty {
                self.service?.createCity(value, state: nil, lat: 0, lon: 0, completion: { [weak self] (city, error) in
                    if let city = city {
                        self?.player?.city = city.shortString
                        self?.player?.cityId = city.firebaseKey
                        self?.inputCity.text = city.shortString
                    } else if let error = error as? NSError {
                        self?.simpleAlert("Could not create city", defaultMessage: nil, error: error)
                    }
                })
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
}
