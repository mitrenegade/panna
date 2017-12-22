//
//  DeepLinkService.swift
//  Balizinha
//
//  Created by Bobby Ren on 12/21/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

enum DeeplinkType {
    enum Messages {
        case root
        case details(id: String)
    }
    case messages(Messages)
    case event(id: String)
    
    // Event links shared should look like: balizinha://event/1
}

class DeepLinkService: NSObject {
    static let shared = DeepLinkService()

    override fileprivate init() {}
    private var deeplinkType: DeeplinkType?

    func checkDeepLink() {
        guard let type = deeplinkType else { return }
        proceedToDeeplink(type)
        
        deeplinkType = nil
    }
    
    func proceedToDeeplink(_ type: DeeplinkType) {
        switch type {
        case .messages(.root):
            displayAlert(title: "Messages Root")
        case .messages(.details(id: let id)):
            displayAlert(title: "Messages Details \(id)")
        case .event(_):
            displayAlert(title: "Event id \(id)")
        }
    }
    
    fileprivate func parseDeepLink(_ url: URL) -> DeeplinkType? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true), let host = components.host else {
            return nil
        }
        var pathComponents = components.path.components(separatedBy: "/")
        // the first component is empty
        pathComponents.removeFirst()
        switch host {
        case "messages":
            if let messageId = pathComponents.first {
                return DeeplinkType.messages(.details(id: messageId))
            }
        case "events":
            if let eventId = pathComponents.first {
                return DeeplinkType.event(id: eventId)
            }
        default:
            break
        }
        return nil
    }
    
    func handle(url: URL) -> Bool{
        deeplinkType = parseDeepLink(url)
        guard let type = deeplinkType else { return false }
        proceedToDeeplink(type)
        return true
    }
    
    fileprivate func displayAlert(title: String) {
        print(title)
    }

}
