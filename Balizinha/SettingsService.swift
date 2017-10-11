//
//  SettingsService.swift
//  Balizinha
//
//  Created by Bobby Ren on 9/19/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

fileprivate var singleton: SettingsService?
class SettingsService: NSObject {
    private var remoteConfig = RemoteConfig.remoteConfig()
    static let defaults: [String: AnyObject] = ["paymentLocation":"profile" as AnyObject]

    static var shared: SettingsService {
        if singleton == nil {
            singleton = SettingsService()
            
        }
        
        return singleton!
    }

    func listenForSettings() {
        _ = self.__once
    }

//    var featureFlags: [String: AnyObject] = [:]
    private lazy var __once: () = {
//        let ref = firRef.child("settings")
//        ref.observe(.value, with: { (snapshot: DataSnapshot) in
//            guard snapshot.exists(), let dict = snapshot.value as? [String: AnyObject] else { return }
//            for (key, val) in dict {
//                self.featureFlags[key] = val
//            }
//            print("feature flags updated: \(self.featureFlags)")
//        })
        self.remoteConfig.setDefaults(defaults as? [String : NSObject])
        self.remoteConfig.fetch(completionHandler: { (status, error) in
            self.remoteConfig.activateFetched()
            print("featureAvailable donation \(SettingsService.donation())")
            print("featureAvailable paymentRequired \(SettingsService.paymentRequired())")
            print("paymentLocation \(SettingsService.shared.featureExperiment("paymentLocation")) testGroup \(SettingsService.paymentLocationTestGroup())")
            
            self.recordExperimentGroups()
        })
    }()
    
    fileprivate func featureAvailable(_ feature: String) -> Bool {
        // feature is off by default. feature flags are used to grant access to test features. when a feature is accepted,
        // the feature flag should be removed from the next build. older builds with the feature flagged have to upgrade
        // or they will lose that feature when the config is removed.
        //guard let available = featureFlags[feature] as? Bool else { return true }
        return self.remoteConfig[feature].boolValue
    }
    
    fileprivate func featureExperiment(_ parameter: String) -> String {
        return self.remoteConfig[parameter].stringValue ?? ""
    }
}

// MARK: - Convenience
extension SettingsService {
    class func donation() -> Bool {
        return shared.featureAvailable("donation")
    }
    
    class func paymentRequired() -> Bool {
        return shared.featureAvailable("paymentRequired")
    }
    
    class func paymentLocationTestGroup() -> Bool {
        let result = shared.featureExperiment("paymentLocation")
        print("Payment location = \(result)")
        return result != defaults["paymentLocation"] as! String
    }
}

// MARK: - Analytics
extension SettingsService {
    func recordExperimentGroups() {
        let paymentLocationGroup = self.featureExperiment("paymentLocation")
        Analytics.setUserProperty(paymentLocationGroup, forName: "PaymentLocation")
    }
}
