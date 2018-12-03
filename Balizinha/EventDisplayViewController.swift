//
//  EventDisplayViewController.swift
// Balizinha
//
//  Created by Tom Strissel on 6/26/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import FBSDKShareKit
import RxSwift
import Balizinha

protocol SectionComponentDelegate: class {
    func componentHeightChanged(controller: UIViewController, newHeight: CGFloat)
}

protocol EventDetailsDelegate: class {
    func didClone(event: Balizinha.Event)
}

class EventDisplayViewController: UIViewController {
    
    @IBOutlet weak var buttonClose: UIButton!
    @IBOutlet weak var buttonShare: UIButton!
    @IBOutlet weak var imageShare: UIImageView!
    @IBOutlet weak var buttonJoin: UIButton!
    @IBOutlet weak var buttonClone: UIButton!
    @IBOutlet weak var imageClone: UIImageView!
    
    @IBOutlet var labelType: UILabel!
    @IBOutlet var labelDate: UILabel!
    @IBOutlet var labelInfo: UILabel!
    @IBOutlet var labelSpotsLeft: UILabel!

    @IBOutlet var sportImageView: RAImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var playersScrollView: PlayersScrollView!
    weak var event : Balizinha.Event?
    let joinHelper = JoinEventHelper()
    
    fileprivate var disposeBag: DisposeBag = DisposeBag()
    
    @IBOutlet var constraintWidth: NSLayoutConstraint!
    @IBOutlet var constraintLocationHeight: NSLayoutConstraint!
    @IBOutlet weak var constraintButtonJoinHeight: NSLayoutConstraint!
    @IBOutlet weak var constraintDetailHeight: NSLayoutConstraint!
    @IBOutlet var constraintPaymentHeight: NSLayoutConstraint?
    @IBOutlet var constraintActivityHeight: NSLayoutConstraint!
    @IBOutlet var constraintInputBottomOffset: NSLayoutConstraint!
    @IBOutlet var constraintInputHeight: NSLayoutConstraint!
    @IBOutlet var constraintSpacerHeight: NSLayoutConstraint!
    @IBOutlet weak var constraintScrollBottomOffset: NSLayoutConstraint!
    
    var organizerController: OrganizerViewController!
    var locationController: ExpandableMapViewController!
    var paymentController: PaymentTypesViewController!
    var activityController: EventActivityViewController!
    var chatController: ChatInputViewController!
    
    @IBOutlet weak var activityView: UIView!
    weak var delegate: EventDetailsDelegate?
    
    lazy var shareService = ShareService()
    let activityOverlay: ActivityIndicatorOverlay = ActivityIndicatorOverlay()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = true

        // Setup event details
        self.view.bringSubview(toFront: labelType.superview!)
        let name = self.event?.name ?? "Balizinha"
        let type = self.event?.type.rawValue ?? ""
        self.labelType.text = "\(name)\n\(type)"
        
        imageShare.image = UIImage(named: "share_icon")?.withRenderingMode(.alwaysTemplate)
        imageClone.image = UIImage(named: "copy30")?.withRenderingMode(.alwaysTemplate)

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

        self.constraintWidth.constant = UIScreen.main.bounds.size.width
        
        // keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        // update payment display
        if SettingsService.paymentRequired() {
            constraintPaymentHeight?.constant = (self.event?.paymentRequired ?? false) ? 40 : 0
        }
        else {
            constraintPaymentHeight?.constant = 0
        }
        
        guard let event = event else {
            imageShare.isHidden = true
            buttonShare.isHidden = true
            constraintButtonJoinHeight.constant = 0
            return
        }
        
        // reserve spot
        listenFor(NotificationType.EventsChanged, action: #selector(refreshJoin), object: nil)
        refreshJoin()
        
        // players
        playersScrollView.delegate = self
        loadPlayers()

        guard let player = PlayerService.shared.current.value else {
            imageShare.isHidden = true
            buttonShare.isHidden = true
            //constraintButtonJoinHeight.constant = 0
            labelSpotsLeft.text = "\(event.numPlayers) are playing"
            self.hideChat()
            
            // guest event
            if let id = DefaultsManager.shared.value(forKey: DefaultsKey.guestEventId.rawValue) as? String, event.id == id {
                buttonClose.isHidden = true
            }
            
            return
        }
        
        if !event.containsPlayer(player) {
            self.hideChat()
        }
        
        // check if user is allowed to clone this event
        buttonClone.isHidden = true
        imageClone.isHidden = true
        if delegate != nil {
            if event.userIsOrganizer {
                buttonClone.isHidden = false
                imageClone.isHidden = false
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
        
        view.addSubview(activityOverlay)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        activityOverlay.setup(frame: view.frame)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = true
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
    
    @IBAction func didClickClose(_ sender: Any?) {
        close()
    }
    
    @IBAction func didClickShare(_ sender: Any?) {
        promptForShare()
    }
    
    @IBAction func didClickJoin(_ sender: Any?) {
        guard let event = event else { return }
        
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
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {[weak self] (action) in
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
        guard let player = PlayerService.shared.current.value else {
            constraintButtonJoinHeight.constant = 0
            labelSpotsLeft.text = "\(event.numPlayers) are playing"
            return
        }
        if event.containsPlayer(player) || event.userIsOrganizer {
            constraintButtonJoinHeight.constant = 0
            labelSpotsLeft.text = "\(event.numPlayers) are playing"
        } else if event.isFull {
            //            buttonJoin.isEnabled = false // may want to add waitlist functionality
            //            buttonJoin.alpha = 0.5
            constraintButtonJoinHeight.constant = 0
            labelSpotsLeft.text = "Event is full"
        } else {
            buttonJoin.isEnabled = true
            buttonJoin.alpha = 1
            let spotsLeft = event.maxPlayers - event.numPlayers
            labelSpotsLeft.text = "\(spotsLeft) spots available"
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
        self.constraintInputHeight.constant = 0
        self.constraintScrollBottomOffset.constant = 0
    }
    
    func promptForShare() {
        guard let event = event else { return }
        var shareMethods: Int = 0
        if ShareService.canSendText {
            shareMethods = shareMethods + 1
        }
        if AuthService.shared.hasFacebookProvider {
            shareMethods = shareMethods + 1
        }

        if shareMethods == 1 {
            // don't prompt, just perform it
            if ShareService.canSendText {
                LoggingService.shared.log(event: LoggingEvent.ShareEventClicked, info: ["method": "contacts"])
                shareService.share(event: event, from: self)
            } else if AuthService.shared.hasFacebookProvider {
                LoggingService.shared.log(event: LoggingEvent.ShareEventClicked, info: ["method": "facebook"])
                shareService.shareToFacebook(link: event.shareLink, from: self)
            }
        } else if shareMethods == 2 {
            // multiple share options are valid, so show options
            let alert = UIAlertController(title: "Share event", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Send to contacts", style: .default, handler: {(action) in
                LoggingService.shared.log(event: LoggingEvent.ShareEventClicked, info: ["method": "contacts"])
                self.shareService.share(event: event, from: self)
            }))
            if AuthService.shared.hasFacebookProvider {
                alert.addAction(UIAlertAction(title: "Share to Facebook", style: .default, handler: {(action) in
                    LoggingService.shared.log(event: LoggingEvent.ShareEventClicked, info: ["method": "facebook"])
                    self.shareService.shareToFacebook(link: event.shareLink, from: self)
                }))
            }
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad){
                alert.popoverPresentationController?.sourceView = buttonShare.superview
                alert.popoverPresentationController?.sourceRect = buttonShare.frame
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    func promptForSignup() {
        guard PlayerService.shared.current.value == nil else { return }

        let alert = UIAlertController(title: "Login or Sign up", message: "Before reserving a spot for this game, you need to join Panna Social Leagues.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {[weak self] (action) in
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
//        controller.delegate = self
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
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        
        self.constraintInputBottomOffset.constant = keyboardHeight
        self.constraintScrollBottomOffset.constant = keyboardHeight + constraintInputHeight.constant
        self.chatController.toggleButton(show: false)
    }
    // MARK - Keyboard
    @objc func keyboardWillHide(_ notification: Notification) {
        self.constraintInputBottomOffset.constant = 0
        self.constraintScrollBottomOffset.constant = constraintInputHeight.constant
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
        let alert = UIAlertController(title: "Success", message: "Event shared!", preferredStyle: UIAlertControllerStyle.alert)
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
    
    func didJoin() {
        // does nothing; currently uses EventsChanged notification for updates
    }
}
