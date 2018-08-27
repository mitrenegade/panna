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

class EventDisplayViewController: UIViewController {
    
    @IBOutlet weak var buttonClose: UIButton!
    @IBOutlet weak var buttonShare: UIButton!
    @IBOutlet weak var imageShare: UIImageView!
    @IBOutlet weak var buttonJoin: UIButton!
    
    @IBOutlet var labelType: UILabel!
    @IBOutlet var labelDate: UILabel!
    @IBOutlet var labelInfo: UILabel!
    @IBOutlet var labelSpotsLeft: UILabel!

    @IBOutlet var sportImageView: RAImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var playersScrollView: PlayersScrollView!
    weak var event : Balizinha.Event?
    let joinHelper = JoinEventHelper()
    
    var alreadyJoined : Bool = false
    
    fileprivate var disposeBag: DisposeBag = DisposeBag()
    
    @IBOutlet var constraintWidth: NSLayoutConstraint!
    @IBOutlet var constraintLocationHeight: NSLayoutConstraint!
    @IBOutlet weak var constraintButtonJoinHeight: NSLayoutConstraint!
    @IBOutlet weak var constraintDetailHeight: NSLayoutConstraint!
    @IBOutlet var constraintPaymentHeight: NSLayoutConstraint!
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
    
    lazy var shareService = ShareService()
    fileprivate let activityOverlay: ActivityIndicatorOverlay = ActivityIndicatorOverlay()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = true

        // Setup event details
        self.view.bringSubview(toFront: labelType.superview!)
        let name = self.event?.name ?? "Balizinha"
        let type = self.event?.type.rawValue ?? ""
        self.labelType.text = "\(name)\n\(type)"
        
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
            } else if let urlString = self?.event?.photoUrl {
                // fall back on photoUrl
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
            self.constraintPaymentHeight.constant = (self.event?.paymentRequired ?? false) ? 40 : 0
        }
        else {
            self.constraintPaymentHeight.constant = 0
        }
        
        guard let event = event else {
            imageShare.isHidden = true
            buttonShare.isHidden = true
            constraintButtonJoinHeight.constant = 0
            return
        }
        
        guard let player = PlayerService.shared.current.value else {
            imageShare.isHidden = true
            buttonShare.isHidden = true
            constraintButtonJoinHeight.constant = 0
            labelSpotsLeft.text = "\(event.numPlayers) are playing"
            self.hideChat()
            return
        }
        
        if event.containsPlayer(player) {
            imageShare.image = UIImage(named: "share_icon")?.withRenderingMode(.alwaysTemplate)
        } else {
            imageShare.isHidden = true
            buttonShare.isHidden = true
            self.hideChat()
        }
        
        // reserve spot
        listenFor(NotificationType.EventsChanged, action: #selector(refreshJoin), object: nil)
        refreshJoin()
        
        // players
        playersScrollView.delegate = self
        loadPlayers()
        
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
        buttonJoin.isEnabled = false
        buttonJoin.alpha = 0.5

        joinHelper.delegate = self
        joinHelper.event = event
        joinHelper.rootViewController = self
        joinHelper.checkIfAlreadyPaid(for: event)
    }

    @objc func close() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc fileprivate func refreshJoin() {
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
        let alert = UIAlertController(title: "Share event", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Send to contacts", style: .default, handler: {[weak self] (action) in
            LoggingService.shared.log(event: LoggingEvent.ShareEventClicked, info: ["method": "contacts"])
            self?.shareEvent()
        }))
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad){
            alert.popoverPresentationController?.sourceView = buttonShare.superview
            alert.popoverPresentationController?.sourceRect = buttonShare.frame
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
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
extension EventDisplayViewController {
    func shareEvent() {
        guard ShareService.canSendText else {
            return }
        guard let event = event else { return  }
        shareService.share(event: event, from: self)
    }
}
/*
extension EventDisplayViewController: FBSDKSharingDelegate {
    // MARK: - FBShare
    func shareEvent2(_ event: Balizinha.Event) {
        let content: FBSDKShareLinkContent = FBSDKShareLinkContent()
        switch event.type {
        case .balizinha:
            content.imageUrl = URL(string: "https://s3-us-west-2.amazonaws.com/lotsportz/static/soccer%403x.png")
            content.contentURL = URL(string: "http://lotsportz.herokuapp.com/soccer")
        case .flagFootball:
            content.imageUrl = URL(string: "https://s3-us-west-2.amazonaws.com/lotsportz/static/football%403x.png")
            content.contentURL = URL(string: "http://lotsportz.herokuapp.com/football")
        case .basketball:
            content.imageUrl = URL(string: "https://s3-us-west-2.amazonaws.com/lotsportz/static/basketball%403x.png")
            content.contentURL = URL(string: "http://lotsportz.herokuapp.com/basketball")
        default:
            content.imageUrl = nil
        }
        
        content.contentTitle = "My event on LotSportz"
        content.contentDescription = "I'm playing \(event.type.rawValue) at \(event.city) on \(event.dateString(event.startTime))"
        
        /*
         This does not use contentTitle and contentDescription if the native app share dialog is used. It only works via web/safari facebook sharing.
         See: http://stackoverflow.com/questions/29916591/fbsdksharelinkcontent-is-not-setting-the-contentdescription-and-contenttitle
         FBSDKShareDialog.showFromViewController(self, withContent: content, delegate: self)
         */
        
        let dialog = FBSDKShareDialog()
        dialog.shareContent = content
        dialog.fromViewController = self
        dialog.mode = FBSDKShareDialogMode.native
        if dialog.canShow() {
            // FB app exists - this share works no matter what
            dialog.show()
        }
        else {
            // FB app not installed on phone. user may have to login
            // this opens a dialog in the app, but link and title are correctly shared.
            dialog.mode = FBSDKShareDialogMode.feedWeb
            dialog.show()
        }
    }

    
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
        print("Error: \(error)")
        let alert = UIAlertController(title: "Error", message: "Event could not be shared at this time.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }

}
 */

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
}
