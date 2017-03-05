//
//  EventDisplayViewController.swift
// Balizinha
//
//  Created by Tom Strissel on 6/26/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import FBSDKShareKit

class EventDisplayViewController: UIViewController, FBSDKSharingDelegate {

    @IBOutlet var labelType: UILabel!
    @IBOutlet var labelDate: UILabel!
    @IBOutlet var labelField: UILabel!
    @IBOutlet var labelCity: UILabel!
    
    @IBOutlet var scrollViewAttendees: UIScrollView!
    
    @IBOutlet var labelDescription: UILabel!
    @IBOutlet var labelNumAttending: UILabel!
    @IBOutlet var labelSpotsAvailable: UILabel!
    @IBOutlet var btnJoin: UIButton!
    @IBOutlet var btnShare: UIButton!
    
    @IBOutlet var sportImageView: UIImageView!
    var event : Event!
    var delegate : AnyObject!
    var alreadyJoined : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(self.close))
        
        // Setup event details
        self.view.bringSubview(toFront: labelType.superview!)
        if let type = self.event.type as? EventType {
            self.labelType.text = type.rawValue
        }
        self.labelDate.text = self.event.dateString(self.event.startTime)
        self.labelField.text = self.event.place
        self.labelCity.text = self.event.city
        self.navigationItem.title = self.event.type.rawValue
        
        if self.event.info == ""{
            self.labelDescription.text = "No further event information at this time."
        }else {
            self.labelDescription.text = "Description: \(self.event.info)"
        }
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

        self.labelType.textColor = UIColor.gray
        self.labelField.textColor = UIColor.gray
        self.labelCity.textColor = UIColor.gray
        self.labelDate.textColor = UIColor.gray

        //Sport image
        switch event.type {
        case .Soccer:
            self.sportImageView.image = UIImage(named: "soccer")
        case .FlagFootball:
            self.sportImageView.image = UIImage(named: "football")
        case .Basketball:
            self.sportImageView.image = UIImage(named: "basketball")
        default:
            print("No image for this sport: using soccer image by default")
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func close() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
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
    
    // MARK: - FBShare
    func shareEvent2(_ event: Event) {
        let content: FBSDKShareLinkContent = FBSDKShareLinkContent()
        switch event.type {
        case .Soccer:
            content.imageURL = URL(string: "https://s3-us-west-2.amazonaws.com/lotsportz/static/soccer%403x.png")
            content.contentURL = URL(string: "http://lotsportz.herokuapp.com/soccer")
        case .FlagFootball:
            content.imageURL = URL(string: "https://s3-us-west-2.amazonaws.com/lotsportz/static/football%403x.png")
            content.contentURL = URL(string: "http://lotsportz.herokuapp.com/football")
        case .Basketball:
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
