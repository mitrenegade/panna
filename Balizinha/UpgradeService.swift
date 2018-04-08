//
//  UpgradeService.swift
//  Balizinha
//
//  Created by Bobby Ren on 4/8/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class UpgradeService: NSObject {
    fileprivate let currentVersion: String!
    fileprivate let newestVersion: String?
    fileprivate let upgradeInterval: TimeInterval!
    fileprivate let defaults: UserDefaults!
    init(currentVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown", newestVersion: String = SettingsService.newestVersion, upgradeInterval: TimeInterval = SettingsService.softUpgradeInterval, defaults: UserDefaults = UserDefaults.standard) {
        self.currentVersion = currentVersion
        self.newestVersion = newestVersion
        self.upgradeInterval = upgradeInterval
        self.defaults = defaults
        
        super.init()
    }
    
    // condition 1: newer version is available
    var newerVersionAvailable: Bool {
        guard let newestVersion = newestVersion else { return false }
        return currentVersion < newestVersion
    }
    
    // condition 2: enough time has passed since last soft upgrade message
    var softUpgradeTimeElapsed: Bool {
        guard let timestamp: Date = defaults.value(forKey: "softUpgradeLastViewTimestamp") as? Date else { return true }
        guard let interval: TimeInterval = upgradeInterval else { return true }
        return Date().timeIntervalSince(timestamp) > interval
    }
    
    // condition 3: user has not opted to never see soft upgrade message
    var neverShowSoftUpgrade: Bool {
        return defaults.bool(forKey: "neverShowSoftUpgrade")
    }
    
    var shouldShowSoftUpgrade: Bool {
        guard newerVersionAvailable else { return false }
        guard softUpgradeTimeElapsed else { return false }
        guard !neverShowSoftUpgrade else { return false }
        
        return true
    }
    
    // after user dismisses Soft Upgrade, set default values as needed
    func softUpgradeDismissed(neverShowAgain: Bool) {
        defaults.set(Date(), forKey: "softUpgradeLastViewTimestamp")
        defaults.set(neverShowAgain, forKey: "neverShowSoftUpgrade")
        defaults.synchronize()
    }
}
