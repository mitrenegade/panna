//
//  ShareService.swift
//  Balizinha
//
//  Created by Bobby Ren on 12/21/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import MessageUI
import Balizinha
import FBSDKShareKit

class ShareService: NSObject {
    class var canSendText:Bool {
        return MFMessageComposeViewController.canSendText()
    }

    func share(from controller: UIViewController, message: String?) {
        let messageComposeVC = MFMessageComposeViewController()
        messageComposeVC.messageComposeDelegate = self  //  Make sure to set this property to self, so that the controller can be dismissed!
        messageComposeVC.recipients = []
        messageComposeVC.body = message ?? "Come join me for some pickup using Panna! Download the app here: http://apple.co/2zeAZ9X"
        controller.present(messageComposeVC, animated: true, completion: nil)
    }
    
    func share(event: Balizinha.Event, from controller: UIViewController) {
        if let eventLink = shareLink(for: event) {
            share(from: controller, message: "Are you down for a game of pickup? Join the event here: \(eventLink).")
        } else {
            // for old events, generate a link and attempt to share it. remove this in 1.0.7
            generateShareLink(event: event) { (link) in
                if let link = link {
                    self.share(from: controller, message: "Are you down for a game of pickup? Join the event here: \(link).")
                } else {
                    self.share(from: controller, message: nil)
                }
            }
        }
    }
    
    // this causes events created before the share service was instanted to generate share links. This should be removed in 1.0.7 or higher.
    func generateShareLink(event: Event, completion: ((String?) -> Void)?) {
        FirebaseAPIService().cloudFunction(functionName: "generateShareLink", params: ["type": "events", "id": event.id]) { [weak self] (result, error) in
            DispatchQueue.main.async {
                if let result = result as? [String: Any], let link = result["shareLink"] as? String {
                    completion?(link)
                } else {
                    completion?(nil)
                }
            }
        }
    }
    
    func shareToFacebook(event: Balizinha.Event, from controller: UIViewController) {
        let content: FBSDKShareLinkContent = FBSDKShareLinkContent()
        if let eventLink = shareLink(for: event), let url = URL(string: eventLink) { // TODO: this url doesn't render or forward correctly on Facebook. For facebook sharing, link to a dynamic website that redirects to the dynamic link in Safari
            content.contentURL = url ?? URL(string: "https://pannaleagues.com")
            FBSDKShareDialog.show(from: controller, with: content, delegate: controller as? FBSDKSharingDelegate)
        }
        //        FirebaseImageService().eventPhotoUrl(for: event) { (url) in
        //            if let url = url {
        //                let photo: FBSDKSharePhoto = FBSDKSharePhoto(imageURL: url, userGenerated: true)
        //                let content = FBSDKSharePhotoContent()
        //                content.photos = [photo]
        //            }
        //        }
        //
    }
    
    fileprivate func shareLink(for event: Event) -> String? {
        //return "panna://events/\(eventId)"
//        let pannaString = TESTING ? "pannadev" : "pannaleagues"
//        return "https://\(pannaString).page.link/events/\(eventId)"
        return event.shareLink
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

