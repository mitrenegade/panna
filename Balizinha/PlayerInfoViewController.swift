//
//  PlayerInfoViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 2/4/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

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

    var player: Player?
    weak var delegate: PlayerDelegate?
    var isCreatingPlayer = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        inputNotes.text = nil
        
        if self.isCreatingPlayer {
            self.title = "New player"
            self.navigationItem.leftBarButtonItem = nil
        }
        else {
            self.title = "Edit player"
            self.navigationItem.rightBarButtonItem = nil

        }
        self.setupTextView()
        self.refresh()
    }
    
    func setupTextView() {
        let keyboardDoneButtonView: UIToolbar = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.black
        keyboardDoneButtonView.tintColor = UIColor.white
        let saveButton: UIBarButtonItem = UIBarButtonItem(title: "Update", style: UIBarButtonItemStyle.done, target: self, action: #selector(dismissKeyboard))
        keyboardDoneButtonView.setItems([saveButton], animated: true)
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
        do {
            if let URL = URL(string: url) {
                let data = try Data(contentsOf: URL)
                if let image = UIImage(data: data) {
                    self.refreshPhoto(photo: image)
                }
            }
        }
        catch {
            print("invalid photo")
        }
    }
    
    func refreshPhoto(photo: UIImage) {
        self.buttonPhoto.setImage(photo, for: .normal)
        buttonPhoto.layer.cornerRadius = buttonPhoto.frame.size.width / 2
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
        self.takePhoto()
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
        if let text = self.inputCity.text, text.characters.count > 0 {
            player.city = text
        }
        if let text = inputNotes.text, text.characters.count > 0 {
            player.info = text
        }

        self.close()
    }
}

// MARK: UITextFieldDelegate
extension PlayerInfoViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let player = self.player else { return }
        if textField == inputName {
            if let text = textField.text, text.characters.count > 0 {
                player.name = text
            }
            else {
                textField.text = player.name
            }
        }
        else if textField == inputCity {
            if let text = textField.text, text.characters.count > 0 {
                player.city = text
            }
            else {
                textField.text = player.city
            }
        }
        
        textField.resignFirstResponder()        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension PlayerInfoViewController: UITextViewDelegate {
    func dismissKeyboard() {
        self.view.endEditing(true)
        
        if let player = self.player {
            player.info = self.inputNotes.text
        }
    }
}

// MARK: Camera
extension PlayerInfoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func takePhoto() {
        self.view.endEditing(true)

        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        }
        else if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            picker.sourceType = .photoLibrary
        }
        else {
            picker.sourceType = .savedPhotosAlbum
        }
        
        self.present(picker, animated: true, completion: nil)
        LogService.log(typeString: "EditMemberPhoto", title: player?.id, message: nil, params: nil, error: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let img = info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]
        guard let photo = img as? UIImage else { return }
        picker.dismiss(animated: true, completion: nil)
        guard let id = self.player?.id else {
            self.simpleAlert("Invalid info", message: "We could not save your photo because your user is invalid. Please log out and log back in.")
            return
        }
        FirebaseImageService.uploadImage(image: photo, type: "player", uid: id, completion: { (url) in
            if let url = url {
                self.player?.photoUrl = url
            }
        })
        self.refreshPhoto(photo: photo)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
