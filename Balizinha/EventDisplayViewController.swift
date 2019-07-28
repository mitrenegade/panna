//
//  EventDisplayViewController.swift
// Balizinha
//
//  Created by Tom Strissel on 6/26/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//
// Fixing layout issues: https://medium.com/@kahseng.lee123/how-to-solve-the-most-common-interface-problems-when-adapting-apps-ui-for-iphone-x-44c0f3c80d84

import UIKit
import FBSDKShareKit
import Balizinha

protocol SectionComponentDelegate: class {
    func componentHeightChanged(controller: UIViewController, newHeight: CGFloat)
}

protocol EventDetailsDelegate: class {
    func didClone(event: Balizinha.Event)
}

class EventDisplayViewController: UIViewController {
    
    @IBOutlet weak var buttonClose: UIButton?
    @IBOutlet weak var buttonShare: UIButton?
    @IBOutlet weak var imageShare: UIImageView?
    @IBOutlet weak var buttonJoin: UIButton!
    @IBOutlet weak var buttonClone: UIButton?
    @IBOutlet weak var imageClone: UIImageView?
    
    @IBOutlet var labelType: UILabel!
    @IBOutlet var labelDate: UILabel!
    @IBOutlet var labelInfo: UILabel!
    @IBOutlet var labelSpotsLeft: UILabel!

    @IBOutlet var sportImageView: RAImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var playersScrollView: PlayersScrollView!
    weak var event : Balizinha.Event?
    let joinHelper = JoinEventHelper()
    
    @IBOutlet var constraintWidth: NSLayoutConstraint!
    @IBOutlet var constraintLocationHeight: NSLayoutConstraint!
    @IBOutlet weak var constraintButtonJoinHeight: NSLayoutConstraint!
    @IBOutlet weak var constraintDetailHeight: NSLayoutConstraint!
    @IBOutlet var constraintPaymentHeight: NSLayoutConstraint?
    @IBOutlet var constraintActivityHeight: NSLayoutConstraint!
    @IBOutlet weak var constraintBottomOffset: NSLayoutConstraint!
    
    var organizerController: OrganizerViewController!
    var locationController: ExpandableMapViewController!
    var paymentController: PaymentTypesViewController!
    var activityController: EventActivityViewController!
    var chatController: ChatInputViewController!
    
    @IBOutlet weak var containerShare: UIView!
    @IBOutlet weak var containerPayment: UIView!
    @IBOutlet weak var containerChatInput: UIView!
    
    @IBOutlet weak var activityView: UIView!
    weak var delegate: EventDetailsDelegate?
    
    lazy var shareService = ShareService()
    let activityOverlay: ActivityIndicatorOverlay = ActivityIndicatorOverlay()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = true
        view.addSubview(activityOverlay)

        // Setup event details
        self.view.bringSubview(toFront: labelType.superview!)
        
        guard let event = event else {
            imageShare?.isHidden = true
            buttonShare?.isHidden = true
            constraintButtonJoinHeight.constant = 0
            return
        }

        let viewModel = EventDetailsViewModel(event: event)

        labelType.text = viewModel.labelTitleText
        labelSpotsLeft.text = viewModel.spotsLeftLabelText

        imageShare?.image = UIImage(named: "share_icon")?.withRenderingMode(.alwaysTemplate)
        imageClone?.image = UIImage(named: "copy30")?.withRenderingMode(.alwaysTemplate)

        if let startTime = self.event?.startTime {
            self.labelDate.text = "\(self.event?.dateString(startTime) ?? "")\n\(self.event?.timeString(startTime) ?? "")"
        }
        else {
            self.labelDate.text = "Start TBD"
        }
        
        if let infoText = self.event?.info, infoText.count > 0 {
            self.labelInfo.text = infoText
            let size = (infoText as NSString).boundingRect(with: CGSize(width: labelInfo.frame.size.width, height: view.frame.size.height), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: labelInfo.font], context: nil)
            constraintDetailHeight.constant = size.height
        } else {
            self.labelInfo.text = nil
            constraintDetailHeight.constant = 0
        }
        
        //Sport image
        FirebaseImageService().eventPhotoUrl(for: event) { [weak self] (url) in
            if let urlString = url?.absoluteString {
                self?.sportImageView.imageUrl = urlString
            } else {
                self?.sportImageView.imageUrl = nil
                self?.sportImageView.image = UIImage(named: "soccer")
            }
        }

        constraintWidth.constant = UIScreen.main.bounds.size.width
        
        // keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        // update payment display
        if SettingsService.paymentRequired() {
            constraintPaymentHeight?.constant = (self.event?.paymentRequired ?? false) ? 40 : 0
        }
        else {
            constraintPaymentHeight?.constant = 0
        }

        // reserve spot
        listenFor(NotificationType.EventsChanged, action: #selector(refreshJoin), object: nil)
        refreshJoin()
        
        // players
        playersScrollView.delegate = self
        loadPlayers()
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)

        // guest event
        if let id = DefaultsManager.shared.value(forKey: DefaultsKey.guestEventId.rawValue) as? String, event.id == id {
            handleGuestEvent()
        }

        guard let player = PlayerService.shared.current.value else {
            imageShare?.isHidden = true
            buttonShare?.isHidden = true
            imageClone?.isHidden = true
            buttonClone?.isHidden = true
            
            self.hideChat()
            return
        }
        
        if !event.containsPlayer(player) && !event.userIsOrganizer {
            self.hideChat()
        }
        
        // check if user is allowed to clone this event
        buttonClone?.isHidden = true
        imageClone?.isHidden = true
        if delegate != nil {
            if event.userIsOrganizer {
                buttonClone?.isHidden = false
                imageClone?.isHidden = false
            } else if let leagueId = event.league {
                // TODO: if user is an organizer of the same league, allow them to clone
            }
        }
        // TODO: do players need to update in real time?
//        EventService.shared.observeUsers(for: event) { (ids) in
//            for id: String in ids {
//                PlayerService.shared.withId(id: id, completion: {[weak self] (player) in
//                    if let player = player {
//                        self?.playersScrollView.addPlayer(player: player)
//                        self?.playersScrollView.refresh()
//                    }
//                })
//            }
//        }
    }
    
    func handleGuestEvent() {
        // handles anonymous user with a guest event
        guard AuthService.isAnonymous, let eventId = DefaultsManager.shared.value(forKey: DefaultsKey.guestEventId.rawValue) as? String, eventId == event?.id else { return }
        
        buttonClose?.isHidden = true
        buttonClose?.isEnabled = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        activityOverlay.setup(frame: view.frame)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = true
        
        NotificationService.shared.resetBadgeCount()
    }
    
    fileprivate func loadPlayers() {
        guard let event = event else { return }
        DispatchQueue.global().async {
            let playerIds = EventService.shared.users(for: event)
            let dispatchGroup = DispatchGroup()
            var players: [Player] = []
            for id: String in playerIds {
                dispatchGroup.enter()
                PlayerService.shared.withId(id: id, completion: {(player) in
                    dispatchGroup.leave()
                    if let player = player {
                        players.append(player)
                    }
                })
            }
            dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
                for player in players {
                    self?.playersScrollView.addPlayer(player: player)
                }
                DispatchQueue.main.async {
                    self?.playersScrollView.refresh()
                }
            }
        }
    }
    
    @objc private func didBecomeActive() {
        loadPlayers()
    }
    
    @IBAction func didClickClose(_ sender: Any?) {
        close()
    }
    
    @IBAction func didClickShare(_ sender: Any?) {
        promptForShare()
    }
    
    @IBAction func didClickJoin(_ sender: Any?) {
        guard let event = event else { return }
        
        if let eventId = DefaultsManager.shared.value(forKey: DefaultsKey.guestEventId.rawValue) as? String, eventId == event.id {
            let title = "Leave \(event.name ?? "event")?"
            let alert = UIAlertController(title: title, message: "You are currently in the event as a guest. If you leave, you will have to sign in to join again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                self.leaveGuestEvent()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }

        guard let current = PlayerService.shared.current.value else {
            if event.paymentRequired {
                promptForSignup() // for a paid event, the user must join. this doesn't happen right now
            } else {
                promptForAnonymousJoin() // for a free event. go through anonymous join flow
            }
            return
        }
        
        guard current.name != nil else {
            if let tab = tabBarController, let controllers = tab.viewControllers, let viewController = controllers[0] as? ConfigurableNavigationController {
                viewController.loadDefaultRootViewController()
            }
            let alert = UIAlertController(title: "Please add your name", message: "Before joining a game, it'll be nice to know who you are. Update your profile now?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                guard let url = URL(string: "panna://account/profile") else { return }
                DeepLinkService.shared.handle(url: url)
            }))
            alert.addAction(UIAlertAction(title: "Not now", style: .cancel, handler: { _ in
                self.doJoinEvent(event)
            }))
            present(alert, animated: true, completion: nil)
            return
        }
        
        doJoinEvent(event)
    }
    
    fileprivate func doJoinEvent(_ event: Balizinha.Event) {
        buttonJoin.isEnabled = false
        buttonJoin.alpha = 0.5

        joinHelper.delegate = self
        joinHelper.event = event
        joinHelper.rootViewController = self
        joinHelper.checkIfPartOfLeague()
    }

    fileprivate func leaveGuestEvent() {
        guard let event = event, let userId = AuthService.currentUser?.uid else { return }
        guard let eventId = DefaultsManager.shared.value(forKey: DefaultsKey.guestEventId.rawValue) as? String, event.id == eventId else {
            DefaultsManager.shared.setValue(nil, forKey: DefaultsKey.guestEventId.rawValue)
            return
        }
        activityOverlay.show()
        EventService.shared.leaveEvent(event, userId: userId) { [weak self] (error) in
            if let error = error as NSError? {
                DispatchQueue.main.async {
                    self?.activityOverlay.hide()
                    self?.simpleAlert("Could not leave game", defaultMessage: "There was an error while trying to leave this game.", error: error)
                }
            } else {
                DispatchQueue.main.async {
                    self?.activityOverlay.hide()
                    NotificationService.shared.removeNotificationForEvent(event)
                }
                DefaultsManager.shared.setValue(nil, forKey: DefaultsKey.guestEventId.rawValue)
                // keep guestPlayerName in defaults
                
                LoggingService.shared.log(event: .GuestEventLeft, info: ["eventId": event.id])
            }
        }
    }
    @IBAction func didClickClone(_ sender: Any?) {
        guard let event = event else { return }
        LoggingService.shared.log(event: .CloneButtonClicked, info: nil)
        delegate?.didClone(event: event)
    }
    
    @objc func close() {
        if let nav = navigationController {
            nav.dismiss(animated: true, completion: nil)
        } else if let presenting = presentingViewController {
            presenting.dismiss(animated: true, completion: nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func refreshJoin() {
        activityOverlay.hide()
        guard let event = event else { return }
        let viewModel = EventDetailsViewModel(event: event)
        labelSpotsLeft.text = viewModel.spotsLeftLabelText

        if let eventId = DefaultsManager.shared.value(forKey: DefaultsKey.guestEventId.rawValue) as? String, eventId == event.id {
            // anon user has joined an event
            constraintButtonJoinHeight.constant = 30 // if refresh is called after joining
            buttonJoin.isEnabled = true
            buttonJoin.alpha = 1
            buttonJoin.setTitle("Leave event", for: .normal)
        } else if let eventId = EventService.shared.featuredEventId, eventId == event.id {
            // anon user has an event invite but has not joined
            if event.isFull {
                constraintButtonJoinHeight.constant = 0
            } else {
                buttonJoin.isEnabled = true
                buttonJoin.alpha = 1
            }
        } else if let player = PlayerService.shared.current.value {
            if event.containsPlayer(player) || event.userIsOrganizer {
                constraintButtonJoinHeight.constant = 0
            } else if event.isFull {
                //            buttonJoin.isEnabled = false // may want to add waitlist functionality
                //            buttonJoin.alpha = 0.5
                constraintButtonJoinHeight.constant = 0
            } else {
                buttonJoin.isEnabled = true
                buttonJoin.alpha = 1
            }
        } else {
            constraintButtonJoinHeight.constant = 0
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EmbedOrganizer" {
            organizerController = segue.destination as? OrganizerViewController
            organizerController.event = event
        }
        else if segue.identifier == "EmbedLocation" {
            locationController = segue.destination as? ExpandableMapViewController
            locationController.event = event
            locationController.delegate = self
        }
        else if segue.identifier == "EmbedPayment" {
            paymentController = segue.destination as? PaymentTypesViewController
            paymentController.event = event
        }
        else if segue.identifier == "EmbedActivity" {
            activityController = segue.destination as? EventActivityViewController
            activityController.event = event
        }
        else if segue.identifier == "EmbedChat" {
            self.chatController = segue.destination as? ChatInputViewController
            self.chatController.event = self.event
        }
    }
    
    func hideChat() {
        containerChatInput.isHidden = true
    }
    
    func promptForShare() {
        guard let event = event, let link = event.shareLink else {
            simpleAlert("Sorry, can't share event", message: "There was an invalid share link or no share link.")
            return
        }
        let shareMethods: [ShareMethod] = shareService.shareMethods

        // multiple share options are valid, so show options
        let alert = UIAlertController(title: "Share event", message: nil, preferredStyle: .actionSheet)
        if shareMethods.contains(.copy) {
            alert.addAction(UIAlertAction(title: "Copy link", style: .default, handler: {(action) in
                LoggingService.shared.log(event: LoggingEvent.ShareEventClicked, info: ["method": ShareMethod.copy.rawValue])
                UIPasteboard.general.string = link
                
                //Alert
                let displayString: String
                if let name = event.name, !name.isEmpty {
                    displayString = name
                } else {
                    displayString = "this event"
                }
                let alertController = UIAlertController(title: "", message: "Copied share link for \(displayString)", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }))
        }
        if shareMethods.contains(.contacts) {
            alert.addAction(UIAlertAction(title: "Send to contacts", style: .default, handler: {(action) in
                LoggingService.shared.log(event: LoggingEvent.ShareEventClicked, info: ["method": ShareMethod.contacts.rawValue])
                self.shareService.share(event: event, from: self)
            }))
        }
        if shareMethods.contains(.facebook) {
            alert.addAction(UIAlertAction(title: "Share to Facebook", style: .default, handler: {(action) in
                LoggingService.shared.log(event: LoggingEvent.ShareEventClicked, info: ["method": ShareMethod.facebook.rawValue])
                self.shareService.shareToFacebook(link: event.shareLink, from: self)
            }))
        }
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad), let button = buttonShare {
            alert.popoverPresentationController?.sourceView = button.superview
            alert.popoverPresentationController?.sourceRect = button.frame
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func promptForSignup() {
        guard PlayerService.shared.current.value == nil else { return }

        let alert = UIAlertController(title: "Login or Sign up", message: "Before reserving a spot for this game, you need to join Panna Social Leagues.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            SplashViewController.shared?.goToSignupLogin()
            LoggingService.shared.log(event: .SignupFromSharedEvent, info: ["action": "OK"])
        }))
        alert.addAction(UIAlertAction(title: "Not now", style: .cancel, handler: { _ in
            LoggingService.shared.log(event: .SignupFromSharedEvent, info: ["action": "Not now"])
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func promptForAnonymousJoin() {
        guard let nav = UIStoryboard(name: "PlayerOnboarding", bundle: nil).instantiateInitialViewController() as? UINavigationController else { return }
        guard let controller = nav.viewControllers.first as? OnboardingNameViewController else { return }
        controller.delegate = self
        controller.event = event
        
        present(nav, animated: true, completion: nil)
    }

}

// MARK: EventDisplayComponentDelegate
extension EventDisplayViewController: SectionComponentDelegate {
    func componentHeightChanged(controller: UIViewController, newHeight: CGFloat) {
        if controller == self.locationController {
            self.constraintLocationHeight.constant = newHeight
        }
        
        if controller != activityController {
            // if other components are small or hidden, increase the chat view
            let height = scrollView.frame.origin.y + scrollView.frame.size.height - activityView.frame.origin.y
            constraintActivityHeight.constant = max(constraintActivityHeight.constant, height)
        }
    }
}

// MARK: Keyboard
extension EventDisplayViewController {
    // MARK - Keyboard
    @objc func keyboardWillShow(_ notification: Notification) {
        let userInfo:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIResponder.keyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        
        self.constraintBottomOffset.constant = keyboardHeight
        self.chatController.toggleButton(show: false)
    }
    // MARK - Keyboard
    @objc func keyboardWillHide(_ notification: Notification) {
        self.constraintBottomOffset.constant = 0
        self.chatController.toggleButton(show: true)
    }
}

// MARK: Sharing
extension EventDisplayViewController: FBSDKSharingDelegate {
    // MARK: - FBSDKSharingDelegate
    func sharerDidCancel(_ sharer: FBSDKSharing!) {
        print("User cancelled sharing.")
    }
    
    func sharer(_ sharer: FBSDKSharing!, didCompleteWithResults results: [AnyHashable: Any]!) {
        let alert = UIAlertController(title: "Success", message: "Event shared!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func sharer(_ sharer: FBSDKSharing!, didFailWithError error: Error!) {
        print("Error: \(String(describing: error))")
        simpleAlert("Could not share", defaultMessage: "Event could not be shared at this time.", error: error as? NSError)
    }
}

extension EventDisplayViewController: PlayersScrollViewDelegate {
    func didSelectPlayer(player: Player) {
        guard let playerController = UIStoryboard(name: "Account", bundle: nil).instantiateViewController(withIdentifier: "PlayerViewController") as? PlayerViewController else { return }
        
        playerController.player = player
        self.navigationController?.pushViewController(playerController, animated: true)
    }
    
    func goToAttendees() {
        // open Attendees list. not used yet but can be used to view/edit attendances
        if let nav = UIStoryboard(name: "Attendance", bundle: nil).instantiateInitialViewController() as? UINavigationController, let controller = nav.viewControllers[0] as? AttendeesViewController {
            controller.event = event
            present(nav, animated: true, completion: nil)
        }
    }
}

extension EventDisplayViewController: JoinEventDelegate {
    func startActivityIndicator() {
        activityOverlay.show()
    }
    
    func stopActivityIndicator() {
        activityOverlay.hide()
    }
    
    func didCancelPayment() {
        activityOverlay.hide()
        buttonJoin.isEnabled = true
        buttonJoin.alpha = 1
    }
    
    func didJoin(_ event: Balizinha.Event?) {
        // only used to display message; currently uses EventsChanged notification for updates
        let title: String
        let message: String
        if UserDefaults.standard.bool(forKey: UserSettings.DisplayedJoinEventMessage.rawValue) == false {
            title = "You've joined a game!"
            message = "You can go to your Calendar to see upcoming games."
            UserDefaults.standard.set(true, forKey: UserSettings.DisplayedJoinEventMessage.rawValue)
            UserDefaults.standard.synchronize()
        } else {
            if let name = event?.name {
                title = "You've joined \(name)"
            } else {
                title = "You've joined a game!"
            }
            message = ""
        }
        simpleAlert(title, message: message, completion: {
        })
    }
}

extension EventDisplayViewController: OnboardingDelegate {
    func didJoinAsGuest() {
        refreshJoin()
        handleGuestEvent()
    }
}
