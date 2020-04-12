//
//  SplashViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 1/19/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Crashlytics
import FirebaseDatabase
import FirebaseAuth
import Balizinha

class SplashViewController: UIViewController {
    var handle: AuthStateDidChangeListenerHandle?
    let disposeBag = DisposeBag()
    static var shared: SplashViewController?

    enum Tab: CaseIterable {
        case leagues
        case map
        case calendar
        case dashboard
    }
    fileprivate var tabs = Tab.allCases
    
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

        AuthService.shared.startup()

        // start listening for user once settingsService returns. only do this once
        SettingsService.shared.observedSettings?.take(1).subscribe(onNext: {[weak self]_ in
            self?.listenForUser()
        }).disposed(by: disposeBag)
        
        SplashViewController.shared = self
    }
    
    func listenForUser() {
        print("LoginLogout: listening for LoginSuccess")
       
        let loginState: Observable<LoginState> = AuthService.shared.loginState.distinctUntilChanged().asObservable()
        let eventId: Observable<Any?> = DefaultsManager.shared.valueStream(for: .guestEventId).distinctUntilChanged({ (val1, val2) -> Bool in
            let str1 = val1 as? String
            let str2 = val2 as? String
            return str1 == str2
        }).asObservable()
        
        Observable<(LoginState, String?)>.combineLatest(loginState, eventId, resultSelector: { state, eventId in
            let guestEventId = eventId as? String
            return (state, guestEventId)
        }).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (state, eventId) in
            if state == .loggedIn {
                self?.didLogin()
            } else if state == .loggedOut {
                if let eventId = eventId {
                    self?.goToGuestEvent(eventId)
                } else {
                    self?.didLogout()
                }
            } else {
                print("State: \(state)")
            }
        }).disposed(by: disposeBag)


        
//        AuthService.shared.loginState.distinctUntilChanged().asObservable().subscribe(onNext: { [weak self] state in
//        }).disposed(by: disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    @objc func didLogin() {
        guard let user = AuthService.currentUser else {
            return
        }
        print("LoginLogout: didLogin userId \(user.uid)")
        Crashlytics.sharedInstance().setUserIdentifier(user.uid)
        
        // loads player from web or cache - don't use player.current yet
        let isFirstLogin = PlayerService.shared.current.value == nil
        PlayerService.shared.withId(id: user.uid) { (player) in
            guard let player = player as? Player else {
                // player does not exist, save/create it.
                // this should have been done on signup
                PlayerService.shared.storeUserInfo()
                return
            }
            player.os = Player.Platform.ios.rawValue // fixme if there's already a value (android) this doesn't change it
            
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
            player.version = "\(version)"
            player.build = "\(build)\(TESTING ? "t" : "")"
            player.lastActiveTimestamp = Date()

            // on first login, downloadFacebookPhoto gets skipped the first time because player has not been created yet
            if isFirstLogin, AuthService.shared.hasFacebookProvider {
                PlayerService.shared.current.accept(player)
                FacebookService.downloadFacebookInfo(completion: { (image, name, error) in
                    if let error = error as NSError?, error.code == 400 {
                        print("error \(error)")
                        AuthService.shared.logout()
                        return
                    }
                    if let name = name {
                        player.name = name
                    }
                })
            }
            
            // start loading stripe account info
            PannaServiceManager.stripeConnectService.startListeningForAccount(userId: player.id)
            PannaServiceManager.stripePaymentService.startListeningForAccount(userId: player.id)
            
            if AuthService.shared.hasFacebookProvider {
                FacebookService.downloadFacebookInfo { (image, name, error) in
                    if let error = error as NSError?, error.code == 400 {
                        print("error \(error)")
                        AuthService.shared.logout()
                        return
                    } // for other errors, ignore but don't load profile
                    
                    if player.name == nil {
                        player.name = name
                    }
                }
            }

            LeagueService.shared.getOwnerLeagueIds(for: player) { [weak self] (results) in
                // causes _playerLeagues to exist, so homeViewController can determine whether user is an owner/organizer
                DispatchQueue.main.async {
                    self?.goToMain()
                }
            }
        }
    
        // notifications
        NotificationService.shared.registerForRemoteNotifications()
    }

    @objc func didLogout() {
        print("LoginLogout: didLogout")
        NotificationService.shared.clearAllNotifications()

        clearUserDefaults()
        if SettingsService.showPreview {
            self.goToPreview()
        }
        else {
            self.goToSignupLogin()
        }
        
        PannaServiceManager.stripePaymentService.resetOnLogout()
        OrganizerService.resetOnLogout()
        
        LeagueService.shared.resetOnLogout()
        PlayerService.resetOnLogout() // TODO: move these to shared instance and use BaseService
        EventService.resetOnLogout()
    }
    
    fileprivate func clearUserDefaults() {
        DefaultsManager.shared.setValue(false, forKey: DefaultsKey.locationPermissionDeniedWarningShown.rawValue)
        
        // create event cached values
        UserDefaults.standard.set(nil, forKey: "organizerCachedName")
        UserDefaults.standard.set(nil, forKey: "organizerCachedPlace")
        UserDefaults.standard.set(nil, forKey: "organizerCachedCity")
        UserDefaults.standard.set(nil, forKey: "organizerCachedState")
        UserDefaults.standard.set(nil, forKey: "organizerCachedLat")
        UserDefaults.standard.set(nil, forKey: "organizerCachedLon")
        UserDefaults.standard.set(nil, forKey: "organizerCachedEventPhotoUrl")
        DefaultsManager.shared.setValue(nil, forKey: "DashboardLeagueId")

        UserDefaults.standard.set(false, forKey: UserSettings.DisplayedJoinEventMessage.rawValue)

        // soft upgrade
        UserDefaults.standard.set(nil, forKey: "softUpgradeLastViewTimestamp")
    }
    
    fileprivate var _homeViewController: UITabBarController?
    fileprivate var homeViewController: UITabBarController {
        if let controller = _homeViewController {
            return controller
        }
        let storyboardName = "Main"
        var sceneId = "PlayerModeTabBarController"
        if SettingsService.showOrganizerDashboard {
            if LeagueService.shared.playerIsOwnerForAnyLeague() {
                sceneId = "OwnerModeTabBarController"
            }
        }
        if AIRPLANE_MODE {
            sceneId = "OwnerModeTabBarController"
        }

        _homeViewController = UIStoryboard(name: storyboardName, bundle: nil).instantiateViewController(withIdentifier: sceneId) as? UITabBarController
        return _homeViewController!
    }
    
    private func goToMain() {
        let index = tabs.firstIndex(of: .map) ?? 0
        homeViewController.selectedIndex = index
        if let presented = presentedViewController {
            guard homeViewController != presented else { return }
            dismiss(animated: true, completion: {
                self.present(self.homeViewController, animated: true, completion: {
                    self.promptForUpgradeIfNeeded()
                    
                    // if we signed up via a deeplink, return to that deeplink
                    DeepLinkService.shared.checkDeepLink()
                })
            })
        } else {
            present(homeViewController, animated: true, completion: {
                //self.testStuffOnLogin()
                self.promptForUpgradeIfNeeded()

                // if we signed up via a deeplink, return to that deeplink
                DeepLinkService.shared.checkDeepLink()
            })
        }

        self.listenFor(NotificationType.DisplayFeaturedEvent, action: #selector(handleEventDeepLink(_:)), object: nil)
        self.listenFor(NotificationType.DisplayFeaturedLeague, action: #selector(handleLeagueDeepLink(_:)), object: nil)

        EventService.shared.listenForEventUsers()
        let _ = PlayerService.shared.current.value // invoke listener
        let _ = OrganizerService.shared // trigger organizer loading
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
        if homeViewController.presentedViewController != nil {
            homeViewController.dismiss(animated: true, completion: nil)
        }
        let index = tabs.firstIndex(of: .calendar) ?? 0
        homeViewController.selectedIndex = index
    }
    
    @objc func goToMap(_ notification: Notification) {
        // TODO: this doesn't work if we're looking at something on top of the tab bar - need to dismiss?
        guard let homeViewController = presentedViewController as? UITabBarController else {
            return
        }
        if homeViewController.presentedViewController != nil {
            homeViewController.dismiss(animated: true, completion: nil)
        }
        let index = tabs.firstIndex(of: .map) ?? 0
        homeViewController.selectedIndex = index
    }
    
    func goToPreview() {
        guard let homeViewController = UIStoryboard(name: "Events", bundle: nil).instantiateInitialViewController() as? MapViewController else { return }
        
        let nav = UINavigationController(rootViewController: homeViewController)

        firAuth.signInAnonymously {[weak self] (user, error) in
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
        
        self.listenFor(NotificationType.DisplayFeaturedEvent, action: #selector(handleEventDeepLink(_:)), object: nil)
        self.listenFor(NotificationType.DisplayFeaturedLeague, action: #selector(handleLeagueDeepLink(_:)), object: nil)
    }

    func goToGuestEvent(_ eventId: String) {
        guard let homeViewController = UIStoryboard(name: "EventDetails", bundle: nil).instantiateViewController(withIdentifier: "EventDisplayViewController") as? EventDisplayViewController else { return }
        EventService.shared.listenForEventUsers()
        EventService.shared.withId(id: eventId) { [weak self] (event) in
            if let event = event as? Balizinha.Event, !event.isPast {
                homeViewController.event = event
                let nav = UINavigationController(rootViewController: homeViewController)
                self?.present(nav, animated: true, completion: nil)
            } else {
                DefaultsManager.shared.setValue(nil, forKey: DefaultsKey.guestEventId.rawValue)
                self?.goToSignupLogin()
            }
        }
    }

    fileprivate func promptForUpgradeIfNeeded() {
        guard UpgradeService().shouldShowSoftUpgrade else { return }

        let title = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "Panna"
        let version = SettingsService.newestVersion
        let alert = UIAlertController(title: "Upgrade available", message: "There is a newer version (\(version)) of \(title) available in the App Store.", preferredStyle: .alert)
        if let url = URL(string: APP_STORE_URL), UIApplication.shared.canOpenURL(url)
        {
            alert.addAction(UIAlertAction(title: "Open in App Store", style: .default, handler: { (action) in
                UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                LoggingService.shared.log(event: .softUpgradeDismissed, info: ["action": "appStore"])
                UpgradeService().softUpgradeDismissed(neverShowAgain: false)
            }))
        }
        alert.addAction(UIAlertAction(title: "Do not show again", style: .default, handler: { (action) in
            UpgradeService().softUpgradeDismissed(neverShowAgain: true)
            LoggingService.shared.log(event: .softUpgradeDismissed, info: ["action": "neverShowAgain"])
        }))
        alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: { (action) in
            UpgradeService().softUpgradeDismissed(neverShowAgain: false)
            LoggingService.shared.log(event: .softUpgradeDismissed, info: ["action": "later"])
        }))
        _homeViewController?.present(alert, animated: true)
    }
}

// deeplinks for notifications
extension SplashViewController {
    @objc func handleEventDeepLink(_ notification: Notification?) {
        guard let userInfo = notification?.userInfo, let eventId = userInfo["eventId"] as? String else { return }
        guard let controller = UIStoryboard(name: "EventDetails", bundle: nil).instantiateViewController(withIdentifier: "EventDisplayViewController") as? EventDisplayViewController else { return }
        EventService.shared.withId(id: eventId) { [weak self] (event) in
            guard let event = event as? Balizinha.Event else { return }
            guard !event.isPast else {
                print("event is past, don't display")
                return
            }
            controller.event = event
            
            if let homeViewController = self?.presentedViewController as? UITabBarController {
                homeViewController.present(controller, animated: true, completion: nil)
            } else if AuthService.isAnonymous {
                self?.presentedViewController?.present(controller, animated: true, completion: nil)
            }
        }
    }
    
    @objc func handleLeagueDeepLink(_ notification: Notification?) {
        guard let userInfo = notification?.userInfo, let leagueId = userInfo["leagueId"] as? String else { return }
        guard let nav = UIStoryboard(name: "League", bundle: nil).instantiateViewController(withIdentifier: "LeagueNavigationController") as? UINavigationController, let controller = nav.viewControllers[0] as? LeagueViewController else { return }
        LeagueService.shared.withId(id: leagueId) { [weak self] (league) in
            guard let league = league as? League else { return }
            controller.league = league
            
            if let homeViewController = self?.presentedViewController as? UITabBarController {
                let index = self?.tabs.firstIndex(of: .leagues) ?? 0
                homeViewController.selectedIndex = index
                homeViewController.present(nav, animated: true, completion: nil)
            } else if AuthService.isAnonymous {
                self?.presentedViewController?.present(nav, animated: true, completion: nil)
            }
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
