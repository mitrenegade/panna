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
    
    func share(event: Event, from controller: UIViewController) {
        let eventId = event.id
        let eventLink = shareLinkFor(event: eventId)
        let message = "Come join me for a game of Balizinha! I'm playing in this game: \(eventLink). Download the app here: http://apple.co/2zeAZ9X"
        share(from: controller, message: message)
    }
    
    fileprivate func shareLinkFor(event eventId: String) -> String{
        return "balizinha://events/\(eventId)"
    }
}

extension ShareService: MFMessageComposeViewControllerDelegate {
    // MFMessageComposeViewControllerDelegate callback - dismisses the view controller when the user is finished with it
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        let resultString: String
        switch result {
        case .cancelled: resultString = "cancelled"
        case .failed: resultString = "failed"
        case .sent: resultString = "sent"
        }
        LoggingService.shared.log(event: LoggingEvent.ShareEventCompleted, info: ["method": "contacts", "result": resultString])
        controller.dismiss(animated: true, completion: nil)
    }
}

