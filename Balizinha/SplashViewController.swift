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
import FirebaseDatabase

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
        }).disposed(by: disposeBag)
        
        SplashViewController.shared = self
    }
    
    func listenForUser() {
        print("LoginLogout: listening for LoginSuccess")
        AuthService.shared.loginState.distinctUntilChanged().asObservable().subscribe(onNext: { [weak self] state in
            if state == .loggedIn {
                self?.didLogin()
            } else if state == .loggedOut {
                self?.didLogout()
            }
        }).disposed(by: disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    @objc func didLogin() {
        print("LoginLogout: didLogin")
        guard let user = AuthService.currentUser else {
            return
        }
        Crashlytics.sharedInstance().setUserIdentifier(user.uid)

        // loads player from web or cache - don't use player.current yet
        PlayerService.shared.withId(id: user.uid) { (player) in
            if let player = player {
                player.os = Player.Platform.ios.rawValue // fixme if there's already a value (android) this doesn't change it
                
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
                let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
                player.appVersion = "\(version) (\(build))"
            } else {
                // player does not exist, save/create it.
                // this should have been done on signup
                PlayerService.shared.storeUserInfo()
            }
        }
        
        if AuthService.shared.hasFacebookProvider {
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
        UserDefaults.standard.set(nil, forKey: "organizerCachedEventPhotoUrl")

        UserDefaults.standard.set(false, forKey: UserSettings.DisplayedJoinEventMessage.rawValue)

        // don't reset showedTutorial
        //UserDefaults.standard.set(true, forKey: "showedTutorial")
        
        // soft upgrade
        UserDefaults.standard.set(nil, forKey: "softUpgradeLastViewTimestamp")
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
        let index = tabs.index(of: "Map") ?? 0
        homeViewController.selectedIndex = index
        if let presented = presentedViewController {
            guard homeViewController != presented else { return }
            dismiss(animated: true, completion: {
                self.present(self.homeViewController, animated: true, completion: {
                    self.promptForUpgradeIfNeeded()
                })
            })
        } else {
            present(homeViewController, animated: true, completion: {
                //self.testStuffOnLogin()
                self.promptForUpgradeIfNeeded()
            })
        }

        if SettingsService.donation() {
            self.listenFor(NotificationType.GoToDonationForEvent, action: #selector(goToCalendar(_:)), object: nil)
        }
        self.listenFor(NotificationType.GoToMapForSharedEvent, action: #selector(goToMap(_:)), object: nil)
        self.listenFor(NotificationType.GoToAccountDeepLink, action: #selector(goToAccount(_:)), object: nil)

        EventService.shared.listenForEventUsers()
        let _ = PlayerService.shared.current.value // invoke listener
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
    
    @objc func goToAccount(_ notification: Notification) {
        // TODO: this doesn't work if we're looking at something on top of the tab bar - need to dismiss?
        guard let homeViewController = presentedViewController as? UITabBarController else {
            return
        }
        if homeViewController.presentedViewController != nil {
            homeViewController.dismiss(animated: true, completion: nil)
        }
        let index = tabs.index(of: "Account") ?? 0
        homeViewController.selectedIndex = index
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
        let index = tabs.index(of: "Calendar") ?? 0
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
        let index = tabs.index(of: "Map") ?? 0
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
    
    fileprivate func promptForUpgradeIfNeeded() {
        guard UpgradeService().shouldShowSoftUpgrade else { return }

        let title = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "Balizinha"
        let version = SettingsService.newestVersion
        let alert = UIAlertController(title: "Upgrade available", message: "There is a newer version (\(version)) of \(title) available in the App Store.", preferredStyle: .alert)
        if let url = URL(string: APP_STORE_URL), UIApplication.shared.canOpenURL(url)
        {
            alert.addAction(UIAlertAction(title: "Open in App Store", style: .default, handler: { (action) in
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
                UpgradeService().softUpgradeDismissed(neverShowAgain: false)
            }))
        }
        alert.addAction(UIAlertAction(title: "Do not show again", style: .default, handler: { (action) in
            UpgradeService().softUpgradeDismissed(neverShowAgain: true)
        }))
        alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: { (action) in
            UpgradeService().softUpgradeDismissed(neverShowAgain: false)
        }))
        _homeViewController?.present(alert, animated: true)
    }
    
    fileprivate func testStuffOnLogin() {
        guard TESTING else { return }
        
        // test event prompt
        let eventId = "-KvVZ-amHak48Czl6fJw"
        guard let homeViewController = presentedViewController as? UITabBarController else {
            return
        }
        let index = tabs.index(of: "Calendar") ?? 0
        homeViewController.selectedIndex = index
        guard let nav: UINavigationController = homeViewController.viewControllers?[index] as? UINavigationController, let calendar: CalendarViewController = nav.viewControllers[0] as? CalendarViewController else { return }
        calendar.promptForDonation(eventId: eventId)
    }
}
