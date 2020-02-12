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



class LoggingService: NSObject, LoggingProvider {
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
        let id = RenderAPIService().uniqueId()
        guard let ref = loggingRef?.child(eventString).child(id) else { return }
        var params = info ?? [:]
        params["timestamp"] = Date().timeIntervalSince1970
        if let current = PlayerService.shared.current.value {
            params["playerId"] = current.id
        }
        ref.updateChildValues(params)
        
        // native firebase analytics
        Analytics.logEvent(eventString, parameters: info)
        
        #if targetEnvironment(simulator)
        var debugString = "LoggingService: event \(event)"
        if info?.isEmpty == false {
            debugString = debugString + " params: \(params)"
        }
        print(debugString)
        #endif
    }
    
    func log(event: LoggingEvent) {
        log(event: event, message: nil, info: nil, error: nil)
    }
    
    func log(event: LoggingEvent, info: [String: Any]? = nil) {
        log(event: event, message: nil, info: info, error: nil)
    }

    func log(event: LoggingEvent, message: String? = nil, info: [String: Any]?, error: NSError?) {
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
