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
import RenderCloud
import RenderPay

protocol OnboardingDelegate: class {
    func didJoinAsGuest()
}

class OnboardingNameViewController: UIViewController {
    @IBOutlet weak var inputName: UITextField!
    @IBOutlet weak var buttonJoin: UIButton!
    @IBOutlet weak var buttonLogin: UIButton!
    @IBOutlet weak var constraintTopOffset: NSLayoutConstraint!
    @IBOutlet weak var constraintBottomOffset: NSLayoutConstraint!
    
    fileprivate let activityOverlay: ActivityIndicatorOverlay = ActivityIndicatorOverlay()
    var event: Balizinha.Event?
    var shouldJoinEvent: Bool = false
    
    let joinHelper = JoinEventHelper()
    weak var delegate: OnboardingDelegate?
    
    var disposeBag: DisposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
        
        view.addSubview(activityOverlay)
        
        if let name = DefaultsManager.shared.value(forKey: DefaultsKey.guestUsername.rawValue) as? String {
            inputName.text = name
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        activityOverlay.setup(frame: view.frame)
    }
    
    @IBAction func didClickJoin(_ sender: Any?) {
        guard let name = inputName.text, !name.isEmpty else { return }
        createPlayer(name: name)
    }

    @IBAction func didClickLogin(_ sender: Any?) {
        SplashViewController.shared?.goToSignupLogin()
        LoggingService.shared.log(event: LoggingEvent.OnboardingSignupClicked, info: nil)
    }
    
    @objc func cancel() {
        view.endEditing(true)
        shouldJoinEvent = false
        navigationController?.dismiss(animated: true, completion: nil)
    }


    @objc func keyboardWillShow(_ notification: Notification) {
        let userInfo:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIResponder.keyboardFrameEndUserInfoKey) as! NSValue
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
    
    @objc func keyboardDidHide() {
        if shouldJoinEvent {
            didClickJoin(nil)
        }
    }
}

// MARK: UITextFieldDelegate
extension OnboardingNameViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        didClickJoin(nil)
        LoggingService.shared.log(event: .GuestEventNameEntered, info: ["name": textField.text ?? "", "eventId": event?.id ?? ""])
        return true
    }
}

extension OnboardingNameViewController {
    func createPlayer(name: String) {
        guard let userId = AuthService.currentUser?.uid else { return }
        guard AuthService.currentUser?.isAnonymous == true else { return }
        guard PlayerService.shared.current.value == nil else { return }
        startActivityIndicator()
        Globals.apiService.cloudFunction(functionName: "createPlayerForAnonymousUser", params: ["userId": userId, "name": name]) { [weak self] (results, error) in
            if let dict = results as? [String: Any] {
                print("Results \(dict)")
                PlayerService.shared.withId(id: userId, completion: { [weak self] (player) in
                    DispatchQueue.main.async {
                        self?.didCreatePlayer(player: player as? Player)
                    }
                })
            } else {
                print("Error: \(String(describing: error))")
                DispatchQueue.main.async {
                    self?.stopActivityIndicator()
                }
            }
        }
    }

    func didCreatePlayer(player: Player?) {
        guard let event = event, let player = player else { return }
        DefaultsManager.shared.setValue(player.name, forKey: DefaultsKey.guestUsername.rawValue)
        
        joinHelper.delegate = self
        joinHelper.event = event
        joinHelper.rootViewController = self
        joinHelper.joinEvent(event, userId: player.id)
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
    
    func didJoin(_ event: Balizinha.Event?) {
        activityOverlay.hide()
        // store current event in defaults as an anonymous-joined event
        guard let event = event else { return }
        let title: String
        let message: String
        if let name = event.name {
            title = "You've joined \(name)"
        } else {
            title = "You've joined a game!"
        }
        message = "Sign up with Panna to view and join more events."
        // TODO: add option to create an account

        simpleAlert(title, message: message, completion: {
            DefaultsManager.shared.setValue(event.id, forKey: DefaultsKey.guestEventId.rawValue)
            self.delegate?.didJoinAsGuest()
            self.dismiss(animated: true) {
            }
            let info: [String: String] = [
                LoggingKey.joinEventClickedResult.rawValue:LoggingValue.JoinEventClickedResult.success.rawValue,
                LoggingKey.eventId.rawValue: event.id,
                LoggingKey.joinLeaveEventSource.rawValue:LoggingValue.JoinLeaveEventSource.guest.rawValue
            ]
            LoggingService.shared.log(event: .JoinEventClicked, info: info)
        })
        LoggingService.shared.log(event: .GuestEventJoined, info: ["eventId": event.id])
    }
}
