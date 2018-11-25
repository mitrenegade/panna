//
//  OnboardingNameViewController.swift
//  Panna
//
//  Created by Bobby Ren on 11/25/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class OnboardingNameViewController: UIViewController {
    @IBOutlet weak var inputName: UITextField!
    @IBOutlet weak var buttonLogin: UIButton!
    @IBOutlet weak var constraintTopOffset: NSLayoutConstraint!
    @IBOutlet weak var constraintBottomOffset: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @IBAction func didClickLogin(_ sender: Any?) {
        SplashViewController.shared?.goToSignupLogin()
        LoggingService.shared.log(event: LoggingEvent.OnboardingSignupClicked, info: nil)
    }
    
    func saveName() {
        print("Done")
    }
    
    @objc func cancel() {
        navigationController?.dismiss(animated: true, completion: nil)
    }


    @objc func keyboardWillShow(_ notification: Notification) {
        let userInfo:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        
        let maxHeight = view.frame.size.height - keyboardHeight
        let bottomVisiblePosition = inputName.frame.origin.y + inputName.frame.size.height + 60
        
        if bottomVisiblePosition > maxHeight {
            let offset = bottomVisiblePosition - maxHeight
            self.constraintTopOffset.constant = -offset
            self.constraintBottomOffset.constant = offset
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    
    @objc func keyboardWillHide(_ notification: Notification) {
        self.constraintTopOffset.constant = 0
        self.constraintBottomOffset.constant = 0
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: UITextFieldDelegate
extension OnboardingNameViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        saveName()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
