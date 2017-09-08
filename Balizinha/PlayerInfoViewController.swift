//
//  PlayerInfoViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 2/4/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import AsyncImageView

protocol PlayerDelegate: class {
    func didUpdatePlayer(player: Player)
}

class PlayerInfoViewController: UIViewController {
    
    @IBOutlet var buttonPhoto: UIButton!
    @IBOutlet var inputName: UITextField!
    @IBOutlet var inputCity: UITextField!
    @IBOutlet var inputNotes: UITextView!
    @IBOutlet var switchInactive: UISwitch!
    @IBOutlet var labelPaymentWarning: UILabel!
    @IBOutlet var buttonPayment: UIButton!
    @IBOutlet var photoView: AsyncImageView!
    
    weak var currentInput: UITextField?

    var player: Player?
    weak var delegate: PlayerDelegate?
    var isCreatingPlayer = false
    
    var cameraController: CameraOverlayViewController?
    
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
    }
    
    func refresh() {
        guard let player = self.player else { return }
        
        if let name = player.name {
            self.inputName.text = name
        }
        if let city = player.city {
            self.inputCity.text = city
        }
        if let notes = player.info {
            self.inputNotes.text = notes
        }
        if let photoUrl = player.photoUrl {
            self.refreshPhoto(url: photoUrl)
        }
    }
    
    func refreshPhoto(url: String) {
        if let URL = URL(string: url) {
            photoView.image = nil
            photoView.showActivityIndicator = true
            photoView.imageURL = URL
            self.photoView.layer.cornerRadius = self.photoView.frame.size.width / 2
        }
        else {
            self.photoView.image = UIImage(named: "add_user")
            self.photoView.layer.cornerRadius = 0
        }
    }
    
    func close() {
        if self.isCreatingPlayer {
            // on signup, don't pop or dismiss
            self.notify(NotificationType.LoginSuccess, object: nil, userInfo: nil)
            return
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
        self.selectPhoto()
    }

    @IBAction func didClickSwitch(_ sender: AnyObject?) {
        // not used
    }
    
    @IBAction func didClickSave(_ sender: AnyObject?) {
        self.view.endEditing(true)

        guard let player = self.player else {
            return
        }
        
        if let text = self.inputName.text, text.characters.count > 0 {
            player.name = text
        }
        else if isCreatingPlayer {
            self.simpleAlert("Please enter a name", message: "Our players would like to know what to call you.")
            return
        }
        
        if let text = self.inputCity.text, text.characters.count > 0 {
            player.city = text
        }
        if let text = inputNotes.text, text.characters.count > 0 {
            player.info = text
        }

        self.close()
    }
    
    func save() {
        self.view.endEditing(true)
        
        player?.info = self.inputNotes.text
        if currentInput == inputName, inputName.text?.isEmpty == false {
            player?.name = inputName.text
        }
        else if currentInput == inputCity, inputCity.text?.isEmpty == false {
            player?.city = inputCity.text
        }
    }

    func cancelEditing() {
        self.view.endEditing(true)
        inputNotes.resignFirstResponder()
        
        inputName.text = player?.name
        inputCity.text = player?.city
        inputNotes.text = player?.info
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
extension PlayerInfoViewController: CameraControlsDelegate {
    func selectPhoto() {
        self.view.endEditing(true)
        
        let controller = CameraOverlayViewController(
            nibName:"CameraOverlayViewController",
            bundle: nil
        )
        controller.delegate = self
        controller.view.frame = self.view.frame
        controller.takePhoto(from: self)
        self.cameraController = controller
        
        // add overlayview
        //ParseLog.log(typeString: "AddEventPhoto", title: nil, message: nil, params: nil, error: nil)
    }
    
    func didTakePhoto(image: UIImage) {
        guard let id = self.player?.id else {
            self.simpleAlert("Invalid info", message: "We could not save your photo because your user is invalid. Please log out and log back in.")
            return
        }
        FirebaseImageService.uploadImage(image: image, type: "player", uid: id, completion: { (url) in
            if let url = url {
                self.refreshPhoto(url: url)
                if let player = PlayerService.shared.current {
                    player.photoUrl = url
                }
            }
        })
        self.photoView.image = image
        self.photoView.layer.cornerRadius = self.photoView.frame.size.width / 2
        
        self.dismissCamera()
    }
    
    func dismissCamera() {
        self.dismiss(animated: true, completion: nil)
    }
}
