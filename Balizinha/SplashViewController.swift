//
//  SplashViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 1/19/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import RxSwift
import FirebaseAuth
import Crashlytics

class SplashViewController: UIViewController {
    var handle: AuthStateDidChangeListenerHandle?
    var loaded = false
    let disposeBag = DisposeBag()
    static var shared: SplashViewController?

    fileprivate var tabs = ["Account", "Map", "Calendar"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if AIRPLANE_MODE {
            let time = DispatchTime.now() + 0.5
            DispatchQueue.main.asyncAfter(deadline: time, execute: {
                self.goToPreview()
            })
            SplashViewController.shared = self
            return
        }
        
        SettingsService.shared.observedSettings?.take(1).subscribe({[weak self]_ in
            self?.listenForUser()
        }).addDisposableTo(self.disposeBag)
        
        SplashViewController.shared = self
    }
    
    func listenForUser() {
        self.handle = firAuth.addStateDidChangeListener({ (auth, user) in
            if self.loaded {
                return
            }
            
            print("auth: \(auth) user: \(user) current \(firAuth.currentUser)")
            if let user = user, !user.isAnonymous {
                // user is logged in
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
                if SettingsService.showPreview {
                    self.goToPreview()
                }
                else {
                    self.goToSignupLogin()
                }
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
        if let user = PlayerService.shared.current {
            let userId = user.id
            Crashlytics.sharedInstance().setUserIdentifier(userId)
        }
        
        self.stopListeningFor(.LoginSuccess)
        self.goToMain()
    }
    
    func didLogout() {
        print("logged out")
        self.stopListeningFor(.LogoutSuccess)
        if #available(iOS 10.0, *) {
            NotificationService.shared.clearAllNotifications()
        }
        
        UserDefaults.standard.set(nil, forKey: "shouldFilterNearbyEvents")
        
        if SettingsService.showPreview {
            self.goToPreview()
        }
        else {
            self.goToSignupLogin()
        }
    }
    
    fileprivate var _homeViewController: UITabBarController?
    fileprivate var homeViewController: UITabBarController {
        if let controller = _homeViewController {
            return controller
        }
        let storyboardName = "Main"
        _homeViewController = UIStoryboard(name: storyboardName, bundle: nil).instantiateInitialViewController() as! UITabBarController
        return _homeViewController!
    }
    
    private func goToMain() {
        let start = tabs.index(of: "Map") ?? 0
        if let presented = presentedViewController {
            guard homeViewController != presented else { return }
            dismiss(animated: true, completion: {
                self.present(self.homeViewController, animated: true, completion: {
                    let index = start
                    self.homeViewController.selectedIndex = index
                })
            })
        } else {
            self.present(homeViewController, animated: true, completion: {
                //self.testStuffOnLogin()
                let index = start
                self.homeViewController.selectedIndex = index
            })
        }

        self.listenFor(NotificationType.LogoutSuccess, action: #selector(SplashViewController.didLogout), object: nil)
        
        if SettingsService.donation() {
            self.listenFor(NotificationType.GoToDonationForEvent, action: #selector(goToCalendar), object: nil)
        }
        EventService.shared.listenForEventUsers()
        PlayerService.shared.current // invoke listener
        let _ = OrganizerService.shared.current // trigger organizer loading
        let _ = PromotionService.shared
        SettingsService.shared.observedSettings?.take(1) // start observing, do nothing with the result
    }
    
    func goToSignupLogin() {
        guard let homeViewController = UIStoryboard(name: "LoginSignup", bundle: nil).instantiateInitialViewController() else { return }
        
        if let presented = presentedViewController {
            guard homeViewController != presented else { return }
            dismiss(animated: true, completion: {
                self._homeViewController = nil
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
        calendar.promptForDonation(eventId: eventId)
    }
    
    func goToPreview() {
        guard let homeViewController = UIStoryboard(name: "Events", bundle: nil).instantiateInitialViewController() as? MapViewController else { return }
        
        let nav = UINavigationController(rootViewController: homeViewController)
        
        firAuth.signInAnonymously { (user, error) in
            print("sign in anonymously with result \(user) error \(error)")
        }
        
        if let presented = presentedViewController {
            guard nav != presented else { return }
            dismiss(animated: true, completion: {
                self._homeViewController = nil
                self.present(nav, animated: true, completion: nil)
            })
        } else {
            present(nav, animated: true, completion: nil)
        }

        self.listenFor(NotificationType.LoginSuccess, action: #selector(SplashViewController.didLogin), object: nil)
    }
    
    fileprivate func testStuffOnLogin() {
        guard TESTING else { return }
        
        // test event prompt
        let eventId = "-KvVZ-amHak48Czl6fJw"
        guard let homeViewController = presentedViewController as? UITabBarController else {
            return
        }
        let index = 2
        homeViewController.selectedIndex = index
        guard let nav: UINavigationController = homeViewController.viewControllers?[index] as? UINavigationController, let calendar: CalendarViewController = nav.viewControllers[0] as? CalendarViewController else { return }
        calendar.promptForDonation(eventId: eventId)
    }
}
