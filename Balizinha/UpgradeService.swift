//
//  UpgradeService.swift
//  Balizinha
//
//  Created by Bobby Ren on 4/8/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class UpgradeService: NSObject {
    static var shared: UpgradeService = UpgradeService()

    override init() {
        super.init()
        
        if !isMostRecentVersion {
            print("doh")
        } else {
            print("Current version is fine: \(SettingsService.currentVersion)")
        }
    }
    
    var isMostRecentVersion: Bool {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let newestVersion = SettingsService.currentVersion
        return version == newestVersion
    }
}
