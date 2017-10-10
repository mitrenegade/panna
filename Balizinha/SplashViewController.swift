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
    
    var handle: AuthStateDidChangeListenerHandle?
    var loaded = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.handle = firAuth.addStateDidChangeListener({ (auth, user) in
            if self.loaded {
                return
            }
            
            if let user = user {
                // user is logged in
                print("auth: \(auth) user: \(user) current \(firAuth.currentUser)")
                self.goToMain()
                
                // pull user data from facebook
                // must be done after playerRef is created
                for provider in user.providerData {
                    if provider.providerID == "facebook.com" {
                        /*
                         // do not always pull facebook info
                        PlayerService.shared.createPlayer(name: user.displayName, email: user.email, city: nil, info: nil, photoUrl: user.photoURL?.absoluteString, completion: { (player, error) in
                            print("player \(player) error \(error)")
                        })
                        */
                    }
                }
            }
            else {
                self.goToSignupLogin()
            }
            
            if self.handle != nil {
                firAuth.removeStateDidChangeListener(self.handle!)
                self.loaded = true
                self.handle = nil
            }
            
            // TODO: firebase does not remove user on deletion of app
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
        if #available(iOS 10.0, *) {
            NotificationService.clearAllNotifications()
        }
        
        self.goToSignupLogin()
    }
    
    private func goToMain() {
        guard let homeViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? UITabBarController else { return }
        homeViewController.selectedIndex = 1
        
        if let presented = presentedViewController {
            guard homeViewController != presented else { return }
            dismiss(animated: true, completion: {
                self.present(homeViewController, animated: true, completion: { 
                })
            })
        } else {
            self.present(homeViewController, animated: true, completion: {
            })
        }

        self.listenFor(NotificationType.LogoutSuccess, action: #selector(SplashViewController.didLogout), object: nil)
        
        if SettingsService.shared.featureAvailable(feature: "donation") {
            self.listenFor(NotificationType.GoToDonationForEvent, action: #selector(goToCalendar), object: nil)
        }
        EventService.shared.listenForEventUsers()
        PlayerService.shared.current // invoke listener
        let _ = OrganizerService.shared.current // trigger organizer loading
        let _ = PromotionService.shared
        SettingsService.shared.listenForSettings()
    }
    
    func goToSignupLogin() {
        guard let homeViewController = UIStoryboard(name: "LoginSignup", bundle: nil).instantiateInitialViewController() else { return }
        
        if let presented = presentedViewController {
            guard homeViewController != presented else { return }
            dismiss(animated: true, completion: {
                self.present(homeViewController, animated: true, completion: nil)
            })
        } else {
            present(homeViewController, animated: true, completion: nil)
        }
        
        self.listenFor(NotificationType.LoginSuccess, action: #selector(SplashViewController.didLogin), object: nil)
    }
    
    func goToCalendar(notification: Notification) {
        // TODO: this doesn't work if we're looking at something on top of the tab bar - need to dismiss?
        guard let homeViewController = presentedViewController as? UITabBarController else {
            return
        }
        guard let info = notification.userInfo, let eventId = info["eventId"] as? String else {
            return
        }
        let index = 2
        homeViewController.selectedIndex = index
        guard let nav: UINavigationController = homeViewController.viewControllers?[index] as? UINavigationController, let calendar: CalendarViewController = nav.viewControllers[0] as? CalendarViewController else { return }
        EventService.shared.withId(id: eventId) { (event) in
            if let event = event {
                calendar.promptForDonation(event: event)
            }
        }
    }
}
