//
//  SignupViewController.swift
// Balizinha
//
//  Created by Bobby Ren on 5/8/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import RxSwift
import RxOptional
import Balizinha
import FirebaseAuth

class SignupViewController: UIViewController {

    @IBOutlet weak var inputEmail: UITextField!
    @IBOutlet weak var inputPassword: UITextField!
    @IBOutlet weak var inputConfirmation: UITextField!
    @IBOutlet weak var buttonSignup: UIButton!
    fileprivate let disposeBag = DisposeBag()
    
    fileprivate let activityOverlay: ActivityIndicatorOverlay = ActivityIndicatorOverlay()
    var shouldCancelInput: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let keyboardNextButtonView = UIToolbar()
        keyboardNextButtonView.sizeToFit()
        keyboardNextButtonView.barStyle = UIBarStyle.black
        keyboardNextButtonView.isTranslucent = true
        keyboardNextButtonView.tintColor = UIColor.white
        let button: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(cancelInput))
        let flex: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        keyboardNextButtonView.setItems([flex, button], animated: true)
        
        inputEmail.inputAccessoryView = keyboardNextButtonView
        inputPassword.inputAccessoryView = keyboardNextButtonView
        inputConfirmation.inputAccessoryView = keyboardNextButtonView
        
        view.addSubview(activityOverlay)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.backgroundColor = .clear
        self.navigationController?.navigationBar.barStyle = .default
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        activityOverlay.setup(frame: view.frame)
    }

    @IBAction func didClickButton(_ button: UIButton) {
        if button == self.buttonSignup {
            self.createEmailUser()
        }
    }
    
    func createEmailUser() {
        guard let email = self.inputEmail.text, !email.isEmpty else {
            self.simpleAlert("Please enter your email", message: nil)
            return
        }
        guard let password = self.inputPassword.text, !password.isEmpty else {
            self.simpleAlert("Please enter your password", message: nil)
            return
        }
        guard let confirmation = self.inputConfirmation.text, confirmation == password else {
            self.simpleAlert("Password and confirmation must match", message: nil)
            return
        }
        
        activityOverlay.show()
        firAuth.createUser(withEmail: email, password: password) { [weak self] (result, error) in
            if let error = error as NSError? {
                print("Error: \(error)")
                self?.activityOverlay.hide()
                self?.simpleAlert("Could not sign up", defaultMessage: nil, error: error)
            }
            else {
                print("createUser results: \(String(describing: result))")
                AuthService.shared.loginUser(email: email, password: password, completion: { [weak self] (error) in
                    self?.activityOverlay.hide()
                    if let error = error as NSError? {
                        self?.simpleAlert("Could not log in", defaultMessage: nil, error: error)
                    }
                    else if result != nil {
                        PlayerService.shared.needsToCreateProfile = true

//                        guard let disposeBag = self?.disposeBag else { return }
//                        let _ = PlayerService.shared.current.value // invoke listener
//                        PlayerService.shared.current.asObservable().filterNil().take(1).subscribe(onNext: { (player) in
//                            PlayerService.shared.needsToCreateProfile = true
//                        }).disposed(by: disposeBag)
                    } else {
                        self?.simpleAlert("Could not log in", message: "Unknown error.")
                    }
                })
            }
        }
    }
}

extension SignupViewController: UITextFieldDelegate {
    @objc fileprivate func cancelInput() {
        shouldCancelInput = true
        view.endEditing(true)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        shouldCancelInput = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard !shouldCancelInput else { return }
        if textField == inputEmail {
            inputPassword.becomeFirstResponder()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
