//
//  OnboardingNameViewController.swift
//  Panna
//
//  Created by Bobby Ren on 11/25/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha
import RxSwift

class OnboardingNameViewController: UIViewController {
    @IBOutlet weak var inputName: UITextField!
    @IBOutlet weak var buttonLogin: UIButton!
    @IBOutlet weak var constraintTopOffset: NSLayoutConstraint!
    @IBOutlet weak var constraintBottomOffset: NSLayoutConstraint!
    
    fileprivate let activityOverlay: ActivityIndicatorOverlay = ActivityIndicatorOverlay()
    var event: Balizinha.Event?
    
    let joinHelper = JoinEventHelper()
    
    var disposeBag: DisposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        view.addSubview(activityOverlay)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        activityOverlay.setup(frame: view.frame)
    }

    @IBAction func didClickLogin(_ sender: Any?) {
        SplashViewController.shared?.goToSignupLogin()
        LoggingService.shared.log(event: LoggingEvent.OnboardingSignupClicked, info: nil)
    }
    
    func saveName() {
        print("Done")
        guard let name = inputName.text, !name.isEmpty else { return }
        DefaultsManager.shared.setValue(name, forKey: "guestUsername")
        
        createPlayer(name: name)
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

extension OnboardingNameViewController {
    func createPlayer(name: String) {
        guard let userId = AuthService.currentUser?.uid else { return }
        guard AuthService.currentUser?.isAnonymous == true else { return }
        guard PlayerService.shared.current.value == nil else { return }
        activityOverlay.show()
        FirebaseAPIService().cloudFunction(functionName: "createPlayerForAnonymousUser", params: ["userId": userId, "name": name]) { [weak self] (results, error) in
            if let dict = results as? [String: Any] {
                print("Results \(dict)")
                PlayerService.shared.withId(id: userId, completion: { [weak self] (player) in
                    DispatchQueue.main.async {
                        self?.didCreatePlayer(player: player)
                    }
                })
            } else {
                print("Error: \(String(describing: error))")
                DispatchQueue.main.async {
                    self?.activityOverlay.hide()
                }
            }
        }
    }

    func didCreatePlayer(player: Player?) {
        guard let event = event else { return }
        PlayerService.shared.refreshCurrentPlayer()
        PlayerService.shared.current.asObservable().filterNil().take(1).subscribe(onNext: { [weak self] (player) in
            self?.disposeBag = DisposeBag()
            self?.joinHelper.delegate = self
            self?.joinHelper.event = event
            self?.joinHelper.rootViewController = self
            self?.joinHelper.checkIfAlreadyPaid()
        }).disposed(by: disposeBag)
    }

    // use this to create a user out of the existing user when the user decides to sign up
//    func createEmailUser() {
//        guard let name = self.inputConfirmation.text, confirmation == password else {
//            self.simpleAlert("Password and confirmation must match", message: nil)
//            return
//        }
//        
//        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
//        firAuth.currentUser?.linkAndRetrieveData(with: credential, completion: { [weak self] (result, error) in
//            if let error = error as NSError? {
//                print("Error: \(error)")
//                self?.simpleAlert("Could not sign up", defaultMessage: nil, error: error)
//            }
//            else {
//                print("createUser results: \(String(describing: result))")
//                AuthService.shared.loginUser(email: email, password: password, completion: { [weak self] (error) in
//                    if let error = error as NSError? {
//                        print("Error: \(error)")
//                        self?.simpleAlert("Could not log in", defaultMessage: nil, error: error)
//                    }
//                    else if let user = result {
//                        guard let disposeBag = self?.disposeBag else { return }
//                        let _ = PlayerService.shared.current.value // invoke listener
//                        PlayerService.shared.current.asObservable().filterNil().take(1).subscribe(onNext: { (player) in
//                            PlayerService.shared.needsToCreateProfile = true
//                        }).disposed(by: disposeBag)
//                        
//                        // create player manually for API v1.4
//                        let params: [String: Any] = ["userId" : user.uid, "email": email]
//                        FirebaseAPIService().cloudFunction(functionName: "onEmailSignupV1_4", params: params, completion: { (result, error) in
//                            print("onEmailSignupV1_4 result \(result) error \(error)")
//                            PlayerService.shared.refreshCurrentPlayer()
//                        })
//                    } else {
//                        self?.simpleAlert("Could not log in", message: "Unknown error. Result: \(result)")
//                    }
//                })
//            }
//        })
//    }
}

extension OnboardingNameViewController: JoinEventDelegate {
    func startActivityIndicator() {
        activityOverlay.show()
    }
    
    func stopActivityIndicator() {
        activityOverlay.hide()
    }
    
    func didCancelPayment() {
        // not used
    }
    
    func didJoin() {
        activityOverlay.hide()
        // TODO: ask if the user wants to create an account
        
        // store current event in defaults as an anonymous-joined event
        if let event = event {
            DefaultsManager.shared.setValue(event.id, forKey: DefaultsKey.guestEventId.rawValue)
        }
    }
}
