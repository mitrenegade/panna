//
//  ShareService.swift
//  Balizinha
//
//  Created by Bobby Ren on 12/21/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import MessageUI

class ShareService: NSObject {
    class var canSendText:Bool {
        return MFMessageComposeViewController.canSendText()
    }

    func share(from controller: UIViewController, message: String?) {
        let messageComposeVC = MFMessageComposeViewController()
        messageComposeVC.messageComposeDelegate = self  //  Make sure to set this property to self, so that the controller can be dismissed!
        messageComposeVC.recipients = []
        messageComposeVC.body = message ?? "Come join me for a game of Balizinha! https://itunes.apple.com/us/app/balizinha/id1198807198?mt=8"
        controller.present(messageComposeVC, animated: true, completion: nil)
    }
}

extension ShareService: MFMessageComposeViewControllerDelegate {
    // MFMessageComposeViewControllerDelegate callback - dismisses the view controller when the user is finished with it
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
}

