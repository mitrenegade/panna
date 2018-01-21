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
    let disposeBag = DisposeBag()
    static var shared: SplashViewController?

    fileprivate var tabs = ["Account", "Map", "Calendar"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if AIRPLANE_MODE {
            let time = DispatchTime.now() + 0.5
            DispatchQueue.main.asyncAfter(deadline: time, execute: {
                self.goToMain()
            })
            SplashViewController.shared = self
            return
        }
        
        if UserDefaults.standard.value(forKey: "appFirstTimeOpened") == nil {
            //if app is first time opened, make sure no auth exists in keychain from previously deleted app
            UserDefaults.standard.setValue(true, forKey: "appFirstTimeOpened")
            // signOut from FIRAuth
            try! firAuth.signOut()
        }

        // start listening for user once settingsService returns. only do this once
        SettingsService.shared.observedSettings?.take(1).subscribe(onNext: {[weak self]_ in
            self?.listenForUser()
        }).disposed(by: self.disposeBag)
        
        SplashViewController.shared = self

        print("LoginLogout: listening for LoginSuccess")
        listenFor(.LoginSuccess, action: #selector(didLogin), object: nil)
        listenFor(.LogoutSuccess, action: #selector(didLogout), object: nil)
    }
    
    func listenForUser() {
        print("LoginLogout: start listening for user")
        self.handle = firAuth.addStateDidChangeListener({ (auth, user) in
            print("LoginLogout: auth state changed: \(auth) user: \(user) current \(PlayerService.currentUser)")
            if let user = user, !user.isAnonymous {
                self.alreadyLoggedIn() // app started already logged in

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
                print("LoginLogout: removing state listener")
                firAuth.removeStateDidChangeListener(self.handle!)
                self.handle = nil
            }
            
            // TODO: firebase does not remove user on deletion of app
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    deinit {
        stopListeningFor(.LoginSuccess)
        stopListeningFor(.LogoutSuccess)
    }
    
    func alreadyLoggedIn() {
        // user is logged in
        notify(NotificationType.LoginSuccess, object: nil, userInfo: nil)
    }
    
    @objc func didLogin() {
        print("LoginLogout: didLogin")
        if let player = PlayerService.shared.current {
            let userId = player.id
            Crashlytics.sharedInstance().setUserIdentifier(userId)
        }
        
        if PlayerService.shared.hasFacebookProvider {
            PlayerService.shared.downloadFacebookPhoto()
        }
        
        self.goToMain()
        
        // notifications
        if #available(iOS 10.0, *) {
            NotificationService.shared.registerForRemoteNotifications()
        }
    }
    
    @objc func didLogout() {
        print("LoginLogout: didLogout")
        if #available(iOS 10.0, *) {
            NotificationService.shared.clearAllNotifications()
        }
        
        clearUserDefaults()
        if #available(iOS 10.0, *) {
            NotificationService.shared.toggleUserReceivesNotifications(false)
        }
        
        if SettingsService.showPreview {
            self.goToPreview()
        }
        else {
            self.goToSignupLogin()
        }
    }
    
    fileprivate func clearUserDefaults() {
        UserDefaults.standard.set(nil, forKey: "shouldFilterNearbyEvents")
        UserDefaults.standard.set(false, forKey: "locationPermissionDeniedWarningShown")
        UserDefaults.standard.set(false, forKey: kNotificationsDefaultsKey)
        
        // create event cached values
        UserDefaults.standard.set(nil, forKey: "organizerCachedName")
        UserDefaults.standard.set(nil, forKey: "organizerCachedPlace")
        UserDefaults.standard.set(nil, forKey: "organizerCachedCity")
        UserDefaults.standard.set(nil, forKey: "organizerCachedState")
        UserDefaults.standard.set(nil, forKey: "organizerCachedLat")
        UserDefaults.standard.set(nil, forKey: "organizerCachedLon")

        UserDefaults.standard.set(false, forKey: UserSettings.DisplayedJoinEventMessage.rawValue)

        // don't reset showedTutorial
        //UserDefaults.standard.set(true, forKey: "showedTutorial")
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

        if SettingsService.donation() {
            self.listenFor(NotificationType.GoToDonationForEvent, action: #selector(goToCalendar(_:)), object: nil)
        }
        self.listenFor(NotificationType.GoToMapForSharedEvent, action: #selector(goToMap(_:)), object: nil)

        EventService.shared.listenForEventUsers()
        let _ = PlayerService.shared.current // invoke listener
        let _ = OrganizerService.shared.current // trigger organizer loading
        let _ = PromotionService.shared
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
    }
    
    @objc func goToCalendar(_ notification: Notification) {
        // TODO: this doesn't work if we're looking at something on top of the tab bar - need to dismiss?
        guard let homeViewController = presentedViewController as? UITabBarController else {
            return
        }
        guard let info = notification.userInfo, let eventId = info["eventId"] as? String else {
            return
        }
        if homeViewController.presentedViewController != nil {
            homeViewController.dismiss(animated: true, completion: nil)
        }
        let index = 2
        homeViewController.selectedIndex = index
        guard let nav: UINavigationController = homeViewController.viewControllers?[index] as? UINavigationController, let calendar: CalendarViewController = nav.viewControllers[0] as? CalendarViewController else { return }
        calendar.promptForDonation(eventId: eventId)
    }
    
    @objc func goToMap(_ notification: Notification) {
        // TODO: this doesn't work if we're looking at something on top of the tab bar - need to dismiss?
        guard let homeViewController = presentedViewController as? UITabBarController else {
            return
        }
        if homeViewController.presentedViewController != nil {
            homeViewController.dismiss(animated: true, completion: nil)
        }
        let index = 1
        homeViewController.selectedIndex = index
    }
    
    func goToPreview() {
        guard let homeViewController = UIStoryboard(name: "Events", bundle: nil).instantiateInitialViewController() as? MapViewController else { return }
        
        let nav = UINavigationController(rootViewController: homeViewController)

        firAuth.signInAnonymously {[weak self] (user, error) in
            print("sign in anonymously with result \(user) error \(error)")
            if let presented = self?.presentedViewController {
                guard nav != presented else { return }
                self?.dismiss(animated: true, completion: {
                    self?._homeViewController = nil
                    self?.present(nav, animated: true, completion: nil)
                })
            } else {
                self?.present(nav, animated: true, completion: nil)
            }
        }
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
