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
        let defaultFeatureFlags: [String: NSObject] = [:]
        self.remoteConfig.setDefaults(defaultFeatureFlags)
        self.remoteConfig.fetch(completionHandler: { (status, error) in
            self.remoteConfig.activateFetched()
            print("featureAvailable donation \(SettingsService.shared.featureAvailable(feature: "donation"))")
            print("featureAvailable paymentRequired \(SettingsService.shared.featureAvailable(feature: "paymentRequired"))")
        })
    }()

//    func test() {
//        let urlString = "https://us-central1-balizinha-dev.cloudfunctions.net/testFunction"
//        guard let requestUrl = URL(string:urlString) else { return }
//        let request = URLRequest(url:requestUrl)
//        let task = URLSession.shared.dataTask(with: request) {
//            (data, response, error) in
//            if let usableData = data {
//                do {
//                    let json = try JSONSerialization.jsonObject(with: usableData, options: [])
//                    print("json \(json)") //JSONSerialization
//                } catch let error as Error {
//                    print("error \(error)")
//                }
//            }
//            else if let error = error {
//                print("error \(error)")
//            }
//        }
//        task.resume()
//    }
    
    func featureAvailable(feature: String) -> Bool {
        // feature is off by default. feature flags are used to grant access to test features. when a feature is accepted,
        // the feature flag should be removed from the next build. older builds with the feature flagged have to upgrade
        // or they will lose that feature when the config is removed.
        //guard let available = featureFlags[feature] as? Bool else { return true }
        let config = self.remoteConfig.configValue(forKey: feature)
        let available = config.boolValue
        return available
    }
}
