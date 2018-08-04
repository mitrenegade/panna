//
//  LoggingService.swift
//  Balizinha
//
//  Created by Bobby Ren on 9/10/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseCommunity

fileprivate var singleton: LoggingService?
fileprivate var loggingRef: DatabaseReference?

enum LoggingEvent: String {
    case TutorialPageViewed
    case TutorialSkipped
    case show_payment_controller
    case FeatureFlagError
    case BackgroundFetch
    case PushNotificationsToggled
    case PushNotificationReceived
    case PreviewTutorialClicked
    case PreviewEventClicked
    case PreviewSignupClicked
    case AddPromoCode
    case OrganizerSignupPrompt
    
    // sharing
    case ShareEventClicked
    case ShareEventCompleted
    case DeepLinkForSharedEventOpened
    case RecommendedEventCellViewed
    
    // deep links
    case DeepLinkForAccountOpened
    
    // upgrade
    case softUpgradeDismissed
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
