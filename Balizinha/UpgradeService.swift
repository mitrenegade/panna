//
//  UpgradeService.swift
//  Balizinha
//
//  Created by Bobby Ren on 4/8/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class UpgradeService: NSObject {
    // condition 1: newer version is available
    var newerVersionAvailable: Bool {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let newestVersion = SettingsService.currentVersion
        return version < newestVersion
    }
    
    // condition 2: enough time has passed since last soft upgrade message
    var softUpgradeTimeElapsed: Bool {
        guard let timestamp: Date = UserDefaults.standard.value(forKey: "softUpgradeLastViewTimestamp") as? Date else { return true }
        let interval: TimeInterval = SettingsService.softUpgradeInterval
        return Date().timeIntervalSince(timestamp) > interval
    }
    
    // condition 3: user has not opted to never see soft upgrade message
    var neverShowSoftUpgrade: Bool {
        return UserDefaults.standard.bool(forKey: "neverShowSoftUpgrade")
    }
    
    var shouldShowSoftUpgrade: Bool {
        guard newerVersionAvailable else { return false }
        guard softUpgradeTimeElapsed else { return false }
        guard !neverShowSoftUpgrade else { return false }
        
        return true
    }
    
    // after user dismisses Soft Upgrade, set default values as needed
    func softUpgradeDismissed(neverShowAgain: Bool) {
        UserDefaults.standard.set(Date(), forKey: "softUpgradeLastViewTimestamp")
        UserDefaults.standard.set(neverShowAgain, forKey: "neverShowSoftUpgrade")
    }
}
