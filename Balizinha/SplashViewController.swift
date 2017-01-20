//
//  SplashViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 1/19/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Parse
import FirebaseAuth

class SplashViewController: UIViewController {
    
    var handle: FIRAuthStateDidChangeListenerHandle?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.handle = firAuth?.addStateDidChangeListener({ (auth, user) in
            if let user = user {
                // user is logged in
                print("auth: \(auth) user: \(user)")
                self.goToMain()
            }
            else {
                self.goToSignupLogin()
            }
        })

        listenFor(.LoginSuccess, action: #selector(didLogin), object: nil)
        listenFor(.LogoutSuccess, action: #selector(didLogout), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    
    deinit {
        stopListeningFor(.LoginSuccess)
        stopListeningFor(.LogoutSuccess)
    }
    
    func didLogin() {
        print("logged in")
        self.stopListeningFor(.LoginSuccess)
        self.goToMain()
    }
    
    func didLogout() {
        print("logged out")
        self.stopListeningFor(.LogoutSuccess)
        NotificationService.clearAllNotifications()
        
        self.goToSignupLogin()
    }
    
    private func goToMain() {
        guard let homeViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() else { return }

        if let presented = presentedViewController {
            guard homeViewController != presented else { return }
            dismiss(animated: true, completion: nil)
        } else {
            present(homeViewController, animated: true, completion: nil)
        }

        self.listenFor(NotificationType.LogoutSuccess, action: #selector(SplashViewController.didLogout), object: nil)
        EventService.sharedInstance().listenForEventUsers()
    }
    
    func goToSignupLogin() {
        guard let homeViewController = UIStoryboard(name: "LoginSignup", bundle: nil).instantiateInitialViewController() else { return }
        
        if let presented = presentedViewController {
            guard homeViewController != presented else { return }
            dismiss(animated: true, completion: nil)
        } else {
            present(homeViewController, animated: true, completion: nil)
        }

        if self.handle != nil {
            firAuth?.removeStateDidChangeListener(self.handle!)
            self.handle = nil
        }
        
        self.listenFor(NotificationType.LoginSuccess, action: #selector(SplashViewController.didLogin), object: nil)
    }
    
}
