//
//  LoggingService.swift
//  Balizinha
//
//  Created by Bobby Ren on 9/10/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAnalytics
import Balizinha
import RenderCloud

fileprivate var singleton: LoggingService?
fileprivate var loggingRef: DatabaseReference?

enum LoggingEvent: String {
    case TutorialPageViewed
    case TutorialSkipped
    case show_payment_controller
    case FeatureFlagError
    case BackgroundFetch
    case PreviewTutorialClicked
    case PreviewEventClicked
    case PreviewSignupClicked
    case AddPromoCode
    case WebsiteViewedFromAbout
    
    // sharing
    case ShareEventClicked
    case ShareEventCompleted
    case RecommendedEventCellViewed
    case ShareLeagueClicked
    
    // deep links
    case DeepLinkForAccountOpened
    case DeepLinkForSharedEventOpened
    case DeepLinkForSharedLeagueOpened
    
    // prelogin sharing
    case SignupFromSharedEvent
    case SignupFromSharedLeague

    // upgrade
    case softUpgradeDismissed
    
    // create/edit event
    case SearchForVenue
    case EditVenueName
    case LockVenueName
    case DragVenueMap
    case CloneButtonClicked
    case ClonedEvent
    
    // view event details
    case ShowOrHideMap
    
    // edit event details
    case RenameEvent
    case ToggleEventPaymentRequired
    case ChangeEventPaymentAmount
    case DeleteEvent
    
    // push
    case PushNotificationsToggled
    case PushNotificationReceived
    case PushNotificationSubscriptionFailed
    
    // organizer
    case OrganizerSignupPrompt
    case OrganizerNoLeaguesAlert
    
    // guest event
    case GuestEventJoined
    case GuestEventLeft
    case GuestEventNameEntered
    case OnboardingSignupClicked
}

class LoggingService: NSObject {
    private lazy var __once: () = {
        // firRef is the global firebase ref
        loggingRef = firRef.child("logs") // this creates a query on the endpoint /logs
    }()

    // MARK: - Singleton
    static var shared: LoggingService {
        if singleton == nil {
            singleton = LoggingService()
            singleton?.__once
        }
        
        return singleton!
    }

    fileprivate func writeLog(event: LoggingEvent, info: [String: Any]?) {
        let eventString = event.rawValue
        let id = FirebaseAPIService.uniqueId()
        guard let ref = loggingRef?.child(eventString).child(id) else { return }
        var params = info ?? [:]
        params["timestamp"] = Date().timeIntervalSince1970
        if let current = PlayerService.shared.current.value {
            params["playerId"] = current.id
        }
        ref.updateChildValues(params)
        
        // native firebase analytics
        Analytics.logEvent(eventString, parameters: info)
    }
    
    func log(event: LoggingEvent, message: String? = nil, info: [String: Any]?, error: NSError? = nil) {
        var params: [String: Any] = info ?? [:]
        if let message = message {
            params["message"] = message
        }
        if let error = error {
            params["error"] = "\(error)"
        }
        writeLog(event: event, info: params)
    }
}
