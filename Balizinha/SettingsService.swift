//
//  SettingsService.swift
//  Balizinha
//
//  Created by Bobby Ren on 9/19/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseRemoteConfig
import FirebaseAnalytics
import RxSwift
import Balizinha

fileprivate var singleton: SettingsService?
class SettingsService: NSObject {
    private var remoteConfig = RemoteConfig.remoteConfig()
    enum SettingsKey: String {
        case newestVersionIOS
        case eventRadius
        case softUpgradeInterval
        case websiteUrl
        
        // no longer used ?
        case donation
        case paymentRequired
        case organizerPayment
        case ownerPayment
        case maps
        
        // experiments
        case showPreview
        case organizerTrial
    }
    static let defaults: [SettingsKey: Any] = [.newestVersionIOS:"0.1.0",
                                               .eventRadius: EVENT_RADIUS_MILES_DEFAULT,
                                               .softUpgradeInterval: SOFT_UPGRADE_INTERVAL_DEFAULT]

    static var shared: SettingsService {
        if singleton == nil {
            singleton = SettingsService()
        }
        
        return singleton!
    }
    
    // observable
    var observedSettings: Observable<Any>? {
        print("Settings: created observedSettings")
        return Observable.create({ (observer) -> Disposable in
            self.remoteConfig.setDefaults(SettingsService.defaults as? [String : NSObject])
            self.remoteConfig.fetch(completionHandler: { (status, error) in
                self.remoteConfig.activateFetched()
                print("Settings: * featureAvailable donation \(SettingsService.donation())")
                print("Settings: * featureAvailable paymentRequired \(SettingsService.paymentRequired())")
                print("Settings: * featureAvailable ownerPaymentRequired \(SettingsService.ownerPaymentRequired())")
                print("Settings: * featureAvailable maps \(SettingsService.usesMaps)")
                print("Settings: * showPreview \(SettingsService.shared.featureExperiment(.showPreview)) testGroup \(SettingsService.showPreviewTestGroup())")
                print("Settings: * newestVersion \(SettingsService.newestVersion)")
                self.recordExperimentGroups()
                observer.onNext("done")
            })

            return Disposables.create()
        })
    }
    
    fileprivate func featureAvailable(_ feature: SettingsKey) -> Bool {
        // feature is off by default. feature flags are used to grant access to test features. when a feature is accepted,
        // the feature flag should be removed from the next build. older builds with the feature flagged have to upgrade
        // or they will lose that feature when the config is removed.
        //guard let available = featureFlags[feature] as? Bool else { return true }
        return remoteConfig[feature.rawValue].boolValue
    }
    
    fileprivate func featureExperiment(_ parameter: SettingsKey) -> String {
        return remoteConfig[parameter.rawValue].stringValue ?? ""
    }
    
    fileprivate func featureValue(_ parameter: SettingsKey) -> RemoteConfigValue {
        return remoteConfig[parameter.rawValue]
    }
}

// MARK: - Remote settings
extension SettingsService {
    class func donation() -> Bool {
        return shared.featureAvailable(.donation)
    }
    
    class func paymentRequired() -> Bool {
        return shared.featureAvailable(.paymentRequired)
    }

    class func organizerPaymentRequired() -> Bool {
        return shared.featureAvailable(.organizerPayment)
    }
    
    class func ownerPaymentRequired() -> Bool {
        return shared.featureAvailable(.ownerPayment)
    }

    class var usesMaps: Bool {
        return shared.featureAvailable(.maps)
    }
    
    class var eventFilterRadius: Double {
        return shared.featureValue(.eventRadius).numberValue?.doubleValue ?? defaults[.eventRadius] as! Double
    }
    
    class var showPreview: Bool {
        return showPreviewTestGroup()
    }
    
    class var newestVersion: String {
        return shared.featureValue(.newestVersionIOS).stringValue ?? defaults[.newestVersionIOS] as! String
    }
    
    class var softUpgradeInterval: TimeInterval {
        return shared.featureValue(.softUpgradeInterval).numberValue?.doubleValue ?? (defaults[.softUpgradeInterval] as! TimeInterval)
    }
    
    class var websiteUrl: String {
        return shared.featureValue(.websiteUrl).stringValue ?? "" // stringValue for a config doesn't return nil but returns empty string
    }
}

// MARK: - Experiments
extension SettingsService {
    class func showPreviewTestGroup() -> Bool {
        let result = shared.featureExperiment(.showPreview)
        print("show preview = \(result)")
        return result == "true" // returns as string
    }
    
    class func organizerTrialAvailable() -> Bool {
        let result = shared.featureExperiment(.organizerTrial)
        print("organizer trial = \(result)")
        return result == "true"
    }

    // MARK: - Analytics
    func recordExperimentGroups() {
        let previewGroup = self.featureExperiment(.showPreview)
        Analytics.setUserProperty(previewGroup, forName: "ShowPreview")
    }
}

