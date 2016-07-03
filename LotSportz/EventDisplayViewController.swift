//
//  EventDisplayViewController.swift
//  LotSportz
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
    
    @IBOutlet var labelDescription: UILabel!
    @IBOutlet var labelNumAttending: UILabel!
    @IBOutlet var labelSpotsAvailable: UILabel!
    @IBOutlet var btnJoin: UIButton!
    @IBOutlet var btnShare: UIButton!
    
    @IBOutlet var sportImageView: UIImageView!
    var event : Event!
    var delegate : AnyObject!
    var alreadyJoined : Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup event details
        self.view.bringSubviewToFront(labelType.superview!)
        self.labelType.text = self.event.type().rawValue
        self.labelDate.text = self.event.dateString(self.event.startTime())
        self.labelField.text = self.event.place()
        self.labelCity.text = self.event.city()
        self.navigationItem.title = self.event.type().rawValue
        
        if self.event.info() == ""{
            self.labelDescription.text = "No further event information at this time."
        }else {
            self.labelDescription.text = "Description: \(self.event.info())"
        }
        self.labelNumAttending.text = "\(self.event.numPlayers()) attending"
        
        if self.event.isFull(){
            self.labelSpotsAvailable.text = "Event full!"
        } else {
            let spots = self.event.maxPlayers() - self.event.numPlayers()
            if spots == 1{
                self.labelSpotsAvailable.text = "\(spots) spot available"
            } else {
                self.labelSpotsAvailable.text = "\(spots) spots svailable"
            }
        }
        
        //Setup buttons
        self.btnShare.layer.cornerRadius = 4
        self.btnJoin.layer.cornerRadius = 4
        if self.event.isFull(){
            self.btnJoin.enabled = false
        }
        
        if (alreadyJoined != nil) && alreadyJoined{
            self.btnJoin.setTitle("Leave", forState: UIControlState.Normal)
            self.btnJoin.backgroundColor = leaveColor
        }
        
        //Sport image
        switch event.type() {
        case .Soccer:
            self.sportImageView.image = UIImage(named: "soccer")
        case .FlagFootball:
            self.sportImageView.image = UIImage(named: "football")
        case .Basketball:
            self.sportImageView.image = UIImage(named: "basketball")
            self.labelType.textColor = UIColor.grayColor()
            self.labelField.textColor = UIColor.grayColor()
            self.labelCity.textColor = UIColor.grayColor()
            self.labelDate.textColor = UIColor.grayColor()
        default:
            print("No image for this sport: using soccer image by default")
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func didTapButton(sender: UIButton) {
        if sender == btnJoin {
            if (alreadyJoined != nil) && alreadyJoined{
                let delegate = self.delegate as! MyEventsTableViewController
                delegate.joinOrLeaveEvent(self.event, join: false)
            } else  {
                let delegate = self.delegate as! JoinEventsTableViewController
                delegate.joinOrLeaveEvent(self.event, join: true)
            }
            self.navigationController?.popViewControllerAnimated(true)
        } else if sender == btnShare {
            self.shareEvent(self.event)
        }
    }
    

    // MARK: - FBShare
    func shareEvent(event: Event) {
        let content: FBSDKShareLinkContent = FBSDKShareLinkContent()
        content.contentURL = NSURL(string: "https://renderapps.io")
        
        content.imageURL = NSURL(string: "http://static1.squarespace.com/static/5688d7fe5a56682e0b85541a/t/574c51e2b09f953f297d2c56/1464619638609/Man_Sitting.jpg?format=1200w")
        content.contentTitle = "My event on LotSportz"
        content.contentDescription = "I'm attending an event on LotSportz: \(event.type().rawValue) at \(event.city()) on \(event.dateString(event.startTime()))"
        /*
         This does not use contentTitle and contentDescription if the native app share dialog is used. It only works via web/safari facebook sharing.
         See: http://stackoverflow.com/questions/29916591/fbsdksharelinkcontent-is-not-setting-the-contentdescription-and-contenttitle
         FBSDKShareDialog.showFromViewController(self, withContent: content, delegate: self)
         */
        
        let dialog = FBSDKShareDialog()
        dialog.shareContent = content
        dialog.fromViewController = self
        dialog.mode = FBSDKShareDialogMode.Native
        if dialog.canShow() {
            // FB app exists - this share works no matter what
            dialog.show()
        }
        else {
            // FB app not installed on phone. user may have to login
            // this opens a dialog in the app, but link and title are correctly shared.
            dialog.mode = FBSDKShareDialogMode.FeedWeb
            dialog.show()
        }
    }
    
    // MARK: - FBSDKSharingDelegate
    func sharerDidCancel(sharer: FBSDKSharing!) {
        print("User cancelled sharing.")
    }
    
    func sharer(sharer: FBSDKSharing!, didCompleteWithResults results: [NSObject : AnyObject]!) {
        let alert = UIAlertController(title: "Success", message: "Event shared!", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func sharer(sharer: FBSDKSharing!, didFailWithError error: NSError!) {
        print("Error: \(error)")
        let alert = UIAlertController(title: "Error", message: "Event could not be shared at this time.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

}
