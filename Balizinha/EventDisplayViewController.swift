//
//  EventDisplayViewController.swift
// Balizinha
//
//  Created by Tom Strissel on 6/26/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import FBSDKShareKit
import AsyncImageView

protocol EventDisplayComponentDelegate: class {
    func componentHeightChanged(controller: UIViewController, newHeight: CGFloat)
}

class EventDisplayViewController: UIViewController {
    
    @IBOutlet weak var buttonClose: UIButton!
    @IBOutlet weak var buttonShare: UIButton!
    @IBOutlet weak var imageShare: UIImageView!

    @IBOutlet var labelType: UILabel!
    @IBOutlet var labelDate: UILabel!
    @IBOutlet var labelInfo: UILabel!

    @IBOutlet var sportImageView: AsyncImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    weak var event : Event?
    
    weak var delegate : AnyObject?
    var alreadyJoined : Bool = false
    
    @IBOutlet var constraintWidth: NSLayoutConstraint!
    @IBOutlet var constraintLocationHeight: NSLayoutConstraint!
    @IBOutlet weak var constraintReserveHeight: NSLayoutConstraint!
    @IBOutlet weak var constraintDetailHeight: NSLayoutConstraint!
    @IBOutlet var constraintPlayersHeight: NSLayoutConstraint!
    @IBOutlet var constraintPaymentHeight: NSLayoutConstraint!
    @IBOutlet var constraintActivityHeight: NSLayoutConstraint!
    @IBOutlet var constraintInputBottomOffset: NSLayoutConstraint!
    @IBOutlet var constraintInputHeight: NSLayoutConstraint!
    @IBOutlet var constraintSpacerHeight: NSLayoutConstraint!
    @IBOutlet weak var constraintScrollBottomOffset: NSLayoutConstraint!
    
    var organizerController: OrganizerViewController!
    var locationController: ExpandableMapViewController!
    var playersController: PlayersScrollViewController!
    var paymentController: PaymentTypesViewController!
    var activityController: EventActivityViewController!
    var chatController: ChatInputViewController!
    
    @IBOutlet weak var activityView: UIView!
    
    lazy var shareService = ShareService()
    
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
        if let url = event?.photoUrl, let URL = URL(string: url) {
            self.sportImageView.imageURL = URL
        }
        else {
            self.sportImageView.imageURL = nil
            self.sportImageView.image = UIImage(named: "soccer")
        }
        
        self.constraintWidth.constant = UIScreen.main.bounds.size.width
        
        // hide map
        self.locationController.shouldShowMap = false
        
        // keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        if let isPast = self.event?.isPast, isPast {
            self.hideChat()
        }
        
        if let currentUser = firAuth.currentUser, self.event?.containsUser(currentUser) == false {
            self.hideChat()
        }
        
        // update payment display
        if SettingsService.paymentRequired() {
            self.constraintPaymentHeight.constant = (self.event?.paymentRequired ?? false) ? 40 : 0
        }
        else {
            self.constraintPaymentHeight.constant = 0
        }
        
        if let event = event, let currentUser = firAuth.currentUser, event.containsUser(currentUser) {
            imageShare.image = UIImage(named: "share_icon")?.withRenderingMode(.alwaysTemplate)
        } else {
            imageShare.isHidden = true
            buttonShare.isHidden = true
        }
        
        // reserve spot. TODO: enable this
        constraintReserveHeight.constant = 0
    }
    
    @IBAction func didClickClose(_ sender: Any?) {
        close()
    }
    
    @IBAction func didClickShare(_ sender: Any?) {
        promptForShare()
    }

    @objc func close() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EmbedOrganizer" {
            self.organizerController = segue.destination as? OrganizerViewController
            self.organizerController.event = self.event
        }
        else if segue.identifier == "EmbedLocation" {
            self.locationController = segue.destination as? ExpandableMapViewController
            self.locationController.event = self.event
            self.locationController.delegate = self
        }
        else if segue.identifier == "EmbedPlayers" {
            self.playersController = segue.destination as? PlayersScrollViewController
            self.playersController.event = self.event
            self.playersController.delegate = self
        }
        else if segue.identifier == "EmbedPayment" {
            self.paymentController = segue.destination as? PaymentTypesViewController
            self.paymentController.event = self.event
        }
        else if segue.identifier == "EmbedActivity" {
            self.activityController = segue.destination as? EventActivityViewController
            self.activityController.event = self.event
        }
        else if segue.identifier == "EmbedChat" {
            self.chatController = segue.destination as? ChatInputViewController
            self.chatController.event = self.event
        }
    }
    
    func hideChat() {
        self.constraintInputHeight.constant = 0
        self.constraintSpacerHeight.constant = 0
        self.constraintScrollBottomOffset.constant = 0
    }
    
    func promptForShare() {
        let alert = UIAlertController(title: "Share event", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Send to contacts", style: .default, handler: {[weak self] (action) in
            LoggingService.shared.log(event: LoggingEvent.ShareEventClicked, info: ["method": "contacts"])
            self?.shareEvent()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: EventDisplayComponentDelegate
extension EventDisplayViewController: EventDisplayComponentDelegate {
    func componentHeightChanged(controller: UIViewController, newHeight: CGFloat) {
        if controller == self.locationController {
            self.constraintLocationHeight.constant = newHeight
        }
        else if controller == self.playersController {
            self.constraintPlayersHeight.constant = newHeight
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
        self.chatController.toggleButton(show: false)
    }
    // MARK - Keyboard
    @objc func keyboardWillHide(_ notification: Notification) {
        self.constraintInputBottomOffset.constant = 0
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
    func shareEvent2(_ event: Event) {
        let content: FBSDKShareLinkContent = FBSDKShareLinkContent()
        switch event.type {
        case .balizinha:
            content.imageURL = URL(string: "https://s3-us-west-2.amazonaws.com/lotsportz/static/soccer%403x.png")
            content.contentURL = URL(string: "http://lotsportz.herokuapp.com/soccer")
        case .flagFootball:
            content.imageURL = URL(string: "https://s3-us-west-2.amazonaws.com/lotsportz/static/football%403x.png")
            content.contentURL = URL(string: "http://lotsportz.herokuapp.com/football")
        case .basketball:
            content.imageURL = URL(string: "https://s3-us-west-2.amazonaws.com/lotsportz/static/basketball%403x.png")
            content.contentURL = URL(string: "http://lotsportz.herokuapp.com/basketball")
        default:
            content.imageURL = nil
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
