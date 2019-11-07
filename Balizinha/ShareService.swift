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
import RenderCloud

enum ShareMethod: String {
    case copy
    case contacts
    case facebook
}

class ShareService: NSObject {
    var shareMethods: [ShareMethod] {
        var methods: [ShareMethod] = [.copy]
        if MFMessageComposeViewController.canSendText() {
            methods.append(.contacts)
        }
        if AuthService.shared.hasFacebookProvider {
            methods.append(.facebook)
        }
        return methods
    }

    func share(from controller: UIViewController, message: String?) {
        let messageComposeVC = MFMessageComposeViewController()
        messageComposeVC.messageComposeDelegate = self  //  Make sure to set this property to self, so that the controller can be dismissed!
        messageComposeVC.recipients = []
        messageComposeVC.body = message ?? "Come join me for some pickup using Panna! Download the app here: http://apple.co/2zeAZ9X"
        controller.present(messageComposeVC, animated: true, completion: nil)
    }
    
    func share(event: Balizinha.Event, from controller: UIViewController) {
        if let link = event.shareLink {
            share(from: controller, message: "Are you up for playing pickup with us? Join the event here: \(link)")
        } else {
            // for old events, generate a link and attempt to share it. remove this in 1.0.7
            RenderAPIService().cloudFunction(functionName: "generateShareLink", params: ["type": "events", "id": event.id]) { [weak self] (result, error) in
                DispatchQueue.main.async {
                    if let result = result as? [String: Any], let link = result["shareLink"] as? String {
                        self?.share(from: controller, message: "Are you up for playing pickup with us? Join the event here: \(link)")
                    } else {
                        self?.share(from: controller, message: nil)
                    }
                }
            }
        }
    }
    
    func share(league: Balizinha.League, from controller: UIViewController) {
        if let link = league.shareLink {
            share(from: controller, message: "Join my league and play some pickup: \(link)")
        } else {
            // for old events, generate a link and attempt to share it. remove this in 1.0.7
            RenderAPIService().cloudFunction(functionName: "generateShareLink", params: ["type": "leagues", "id": league.id]) { [weak self] (result, error) in
                DispatchQueue.main.async {
                    if let result = result as? [String: Any], let link = result["shareLink"] as? String {
                        self?.share(from: controller, message: "Join my league and play some pickup: \(link)")
                    } else {
                        self?.share(from: controller, message: nil)
                    }
                }
            }
        }
    }

    func shareToFacebook(link: String?, from controller: UIViewController) {
        let content: ShareLinkContent = ShareLinkContent()
        if let link = link, let url = URL(string: link) { // TODO: this url doesn't render or forward correctly on Facebook. For facebook sharing, link to a dynamic website that redirects to the dynamic link in Safari
            content.contentURL = url
            ShareDialog.show(from: controller, with: content, delegate: controller as? SharingDelegate)
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
}

extension ShareService: MFMessageComposeViewControllerDelegate {
    // MFMessageComposeViewControllerDelegate callback - dismisses the view controller when the user is finished with it
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        let resultString: String
        switch result {
        case .cancelled: resultString = "cancelled"
        case .failed: resultString = "failed"
        case .sent: resultString = "sent"
        @unknown default: resultString = "unknown"
        }
        LoggingService.shared.log(event: LoggingEvent.ShareEventCompleted, info: ["method": "contacts", "result": resultString])
        controller.dismiss(animated: true, completion: nil)
    }
}

