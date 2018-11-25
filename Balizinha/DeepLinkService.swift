//
//  DeepLinkService.swift
//  Balizinha
//
//  Created by Bobby Ren on 12/21/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//
// https://medium.com/@stasost/ios-how-to-open-deep-links-notifications-and-shortcuts-253fb38e1696
import UIKit
import Balizinha

enum DeeplinkType {
    enum Messages {
        case root
        case details(String)
    }
    case messages(Messages)
    case event(String)
    case league(String)
    enum AccountActions: String {
        case profile
        case payments
    }
    case account(AccountActions)
    
    // Deep links should look like: balizinha://event/1 or panna://event/1
}

class DeepLinkService: NSObject {
    static let shared = DeepLinkService()

    override fileprivate init() {}
    private var deeplinkType: DeeplinkType?
    
    // if going to account deeplink, use this for any follow up links
    var accountDestination: DeeplinkType.AccountActions?
    
    // opens any cached deeplinks on app startup
    func checkDeepLink() {
        guard let type = deeplinkType else { return }
        proceedToDeeplink(type)
        
        deeplinkType = nil
    }

    // handles deeplinks sent through a click
    func handle(url: URL) -> Bool {
        deeplinkType = parseUniversalLink(url) ?? parseDeepLink(url) // use universal links first, then fall back to deeplink (ios only)
        guard let type = deeplinkType else { return false }
        proceedToDeeplink(type)
        return true
    }

    fileprivate func parseDeepLink(_ url: URL) -> DeeplinkType? {
        // format: panna://events/123
        // scheme = panna
        // host = events
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true), let host = components.host else {
            return nil
        }
        var pathComponents = components.path.components(separatedBy: "/")
        // the first component is empty
        pathComponents.removeFirst()
        switch host {
        case "messages":
            if let messageId = pathComponents.first {
                return DeeplinkType.messages(.details(messageId))
            }
        case "events":
            if let eventId = pathComponents.first {
                return DeeplinkType.event(eventId)
            }
        case "account":
            if let first = pathComponents.first {
                if first == DeeplinkType.AccountActions.profile.rawValue {
                    return DeeplinkType.account(.profile)
                } else if first == DeeplinkType.AccountActions.payments.rawValue {
                    return DeeplinkType.account(.payments)
                }
            }
        default:
            break
        }
        return nil
    }

    fileprivate func parseUniversalLink(_ url: URL) -> DeeplinkType? {
        // format: https://pannaleagues.com/?type=events&id=123
        // scheme = https
        // host = pannaleagues.com
        // queryItems: eventId=123
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        var category: String?
        var idString: String?
        if components.path != "/" { // path components exist
            var pathComponents = components.path.components(separatedBy: "/")
            pathComponents.removeFirst() // the first component is empty
            category = pathComponents.first
            pathComponents.removeFirst()
            idString = pathComponents.first
        } else if let queryItems = components.queryItems, !queryItems.isEmpty {
            print("queryItems \(queryItems)")
            category = queryItems.filter() {$0.name == "type"}.first?.value
            idString = queryItems.filter() {$0.name == "id"}.first?.value
        }

        guard let id = idString else { return nil }
        switch category {
        case "messages":
            return DeeplinkType.messages(.details(id))
        case "events":
            return DeeplinkType.event(id)
        case "leagues":
            return DeeplinkType.league(id)
        default:
            break
        }
        return nil
    }

    
    fileprivate func proceedToDeeplink(_ type: DeeplinkType) {
        switch type {
        case .messages(.root):
            print("Todo: show Messages Root")
        case .messages(.details(let id)):
            print("Todo: show Messages Details \(id)")
        case .event(let id):
            loadAndShowEvent(id)
        case .account(.profile):
            goToAccount(.profile)
            print("profile")
        case .account(.payments):
            goToAccount(.payments)
            print("payment")
        case .league(let id):
            loadAndShowLeague(id)
        }
    }
    
    fileprivate func loadAndShowEvent(_ eventId: String) {
        EventService.shared.withId(id: eventId) { [weak self] event in
            guard let event = event, !event.isPast else { return }
            EventService.shared.featuredEventId = eventId
            self?.notify(.DisplayFeaturedEvent, object: nil, userInfo: ["eventId": eventId])
            LoggingService.shared.log(event: LoggingEvent.DeepLinkForSharedEventOpened, info: ["eventId": eventId])
        }
    }
    
    fileprivate func loadAndShowLeague(_ leagueId: String) {
        LeagueService.shared.withId(id: leagueId) { [weak self] league in
            guard league != nil else { return }
            self?.notify(.DisplayFeaturedLeague, object: nil, userInfo: ["leagueId": leagueId])
            LoggingService.shared.log(event: LoggingEvent.DeepLinkForSharedLeagueOpened, info: ["leagueId": leagueId])
        }
    }
    
    fileprivate func goToAccount(_ accountAction: DeeplinkType.AccountActions) {
        self.accountDestination = accountAction
        self.notify(NotificationType.GoToAccountDeepLink, object: nil, userInfo: nil)
        
        LoggingService.shared.log(event: .DeepLinkForAccountOpened, info: ["destination": accountAction.rawValue])
    }
    
    func clearDestinations() {
        accountDestination = nil
    }
}
