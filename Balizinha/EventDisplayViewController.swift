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

    @IBOutlet var labelType: UILabel!
    @IBOutlet var labelDate: UILabel!
    @IBOutlet var labelInfo: UILabel!

    /*
    @IBOutlet var labelDescription: UILabel!
    @IBOutlet var labelNumAttending: UILabel!
    @IBOutlet var labelSpotsAvailable: UILabel!
    @IBOutlet var btnJoin: UIButton!
    @IBOutlet var btnShare: UIButton!
    */
    
    @IBOutlet var sportImageView: AsyncImageView!
    var event : Event!
    var delegate : AnyObject!
    var alreadyJoined : Bool = false
    
    @IBOutlet var constraintWidth: NSLayoutConstraint!
    @IBOutlet var constraintLocationHeight: NSLayoutConstraint!
    @IBOutlet var constraintPlayersHeight: NSLayoutConstraint!
    @IBOutlet var constraintPaymentHeight: NSLayoutConstraint!
    @IBOutlet var constraintActivityHeight: NSLayoutConstraint!
    @IBOutlet var constraintInputBottomOffset: NSLayoutConstraint!
    @IBOutlet var constraintInputHeight: NSLayoutConstraint!
    @IBOutlet var constraintSpacerHeight: NSLayoutConstraint!
    
    var organizerController: OrganizerViewController!
    var locationController: ExpandableMapViewController!
    var playersController: PlayersScrollViewController!
    var paymentController: PaymentTypesViewController!
    var activityController: EventActivityViewController!
    var chatController: ChatInputViewController!
    
    @IBOutlet weak var activityView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(self.close))
       
        // Setup event details
        self.view.bringSubview(toFront: labelType.superview!)
        let name = self.event.name ?? "Balizinha"
        let type = self.event.type.rawValue
        self.labelType.text = "\(name) (\(type))"
        
        if let startTime = self.event.startTime {
            self.labelDate.text = "\(self.event.dateString(startTime)), \(self.event.timeString(startTime))"
        }
        else {
            self.labelDate.text = "Start TBD"
        }
        
        self.navigationItem.title = self.event.type.rawValue
        
        if self.event.info == ""{
            self.labelInfo.text = "No further event information at this time."
        }else {
            self.labelInfo.text = "Description: \(self.event.info)"
        }
        
        /*
        self.labelNumAttending.text = "\(self.event.numPlayers) attending"
        
        if self.event.isFull{
            self.labelSpotsAvailable.text = "Event full!"
        } else {
            let spots = self.event.maxPlayers - self.event.numPlayers
            if spots == 1{
                self.labelSpotsAvailable.text = "\(spots) spot available"
            } else {
                self.labelSpotsAvailable.text = "\(spots) spots available"
            }
        }
        
        //Setup buttons
        self.btnShare.layer.cornerRadius = 4
        self.btnJoin.layer.cornerRadius = 4
        
        if event.userIsOwner {
            self.btnJoin.setTitle("Edit", for: .normal)
        }
        else if alreadyJoined {
            self.btnJoin.setTitle("Leave", for: UIControlState())
            self.btnJoin.backgroundColor = leaveColor
        }
        else if self.event.isFull{
            self.btnJoin.isEnabled = false
        }
        */

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
        self.locationController.toggleMap(show: false)
        
        // keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        if let isPast = self.event?.isPast, isPast {
            self.hideChat()
        }
        
        if let currentUser = firAuth.currentUser, self.event?.containsUser(currentUser) == false {
            self.hideChat()
        }
        
        if !self.event.paymentRequired {
            self.constraintPaymentHeight.constant = 0
            self.view.setNeedsUpdateConstraints()
            self.view.updateConstraintsIfNeeded()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // make sure table height is exactly correct because autolayout doesn't correctly set it
        /*
        var height = self.view.frame.size.height + 40 - self.activityView.frame.origin.y
        if self.event.isPast {
            height += 40
        }
        
        if height < 80 {
            height = 80 // show at least two rows
        }
        self.constraintActivityHeight.constant = height
        */
    }
    
    func close() {
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
        }
        else if segue.identifier == "EmbedActivity" {
            self.activityController = segue.destination as? EventActivityViewController
            //self.activityController.delegate = self
            self.activityController.event = self.event
        }
        else if segue.identifier == "EmbedChat" {
            self.chatController = segue.destination as? ChatInputViewController
            self.chatController.event = self.event
        }
    }
    
    /*
    @IBAction func didTapButton(_ sender: UIButton) {
        if sender == btnJoin {
            if event.userIsOwner {
                self.simpleAlert("Edit event coming soon", message: "You will be able to edit your event in the next version.")
            }
            else if alreadyJoined {
                let delegate = self.delegate as! CalendarViewController
                delegate.joinOrLeaveEvent(self.event, join: false)
                self.navigationController?.popViewController(animated: true)
            } else  {
                let delegate = self.delegate as! EventsViewController
                delegate.joinOrLeaveEvent(self.event, join: true)
                self.navigationController?.popViewController(animated: true)
            }
        } else if sender == btnShare {
            self.shareEvent2(self.event)
        }
    }
    */
    func hideChat() {
        self.constraintInputHeight.constant = 0
        self.constraintSpacerHeight.constant = 0
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
    func keyboardWillShow(_ notification: Notification) {
        let userInfo:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        
        self.constraintInputBottomOffset.constant = keyboardHeight
        self.chatController.toggleButton(show: false)
    }
    // MARK - Keyboard
    func keyboardWillHide(_ notification: Notification) {
        self.constraintInputBottomOffset.constant = 0
        self.chatController.toggleButton(show: true)
    }
    

}

// MARK: Sharing
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
