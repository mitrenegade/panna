//
//  CameraOverlayViewController.swift
//  rollcall
//
//  Created by Bobby Ren on 3/12/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit


@objc protocol CameraControlsDelegate: class {
    func didTakePhoto(image: UIImage)
    func dismissCamera()
}
class CameraOverlayViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet var buttonCapture: UIButton!
    @IBOutlet var buttonDevice: UIButton!
    @IBOutlet var buttonLibrary: UIButton!
    @IBOutlet var buttonCancel: UIButton!
    
    weak var delegate: CameraControlsDelegate?
    var picker: UIImagePickerController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func takePhoto(from controller: UIViewController) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                picker.sourceType = .photoLibrary
            }
            else {
                picker.sourceType = .savedPhotosAlbum
            }

            controller.present(picker, animated: true, completion: nil)
            self.picker = picker
            return
        }

        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.showsCameraControls = false

        // set up buttons to make them white
        let polaroid = UIImage(imageLiteralResourceName: "polaroid").withRenderingMode(.alwaysTemplate)
        self.buttonLibrary.setImage(polaroid, for: .normal)
        self.buttonLibrary.tintColor = UIColor.white

        let flip = UIImage(imageLiteralResourceName: "flip").withRenderingMode(.alwaysTemplate)
        self.buttonDevice.setImage(flip, for: .normal)
        self.buttonDevice.tintColor = UIColor.white

        // CameraOverlayViewController handles functionality and overlay, but is never presented. Its picker is presented.
        let view = self.view as! CameraOverlayView
        view.controller = self
        
        controller.present(picker, animated: true, completion: nil)
        picker.cameraOverlayView = self.view
        self.picker = picker
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let img = info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]
        guard let photo = img as? UIImage else { return }
        delegate?.didTakePhoto(image: photo)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        delegate?.dismissCamera()
    }
    
    func goToLibrary() {
        let library = UIImagePickerController()
        library.sourceType = .photoLibrary
        library.delegate = self
        self.picker?.present(library, animated: true, completion: nil)
    }
}

class CameraOverlayView: UIView {
    var controller: CameraOverlayViewController?
    
    // this @IBAction must be defined in the custom view because the custom view responds to UI touches, not the controller
    @IBAction func didClickButton(_ sender: UIButton?) {
        if sender == controller?.buttonCapture {
            print("capture")
            controller?.picker?.takePicture()
        }
        else if sender == controller?.buttonDevice {
            print("device")
            if controller?.picker?.cameraDevice == .front {
                controller?.picker?.cameraDevice = .rear
            }
            else {
                controller?.picker?.cameraDevice = .front
            }
        }
        else if sender == controller?.buttonCancel {
            print("cancel")
            controller?.delegate?.dismissCamera()
        }
        else if sender == controller?.buttonLibrary {
            print("library")
            controller?.goToLibrary()
        }
    }
}
