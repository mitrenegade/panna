//
//  UpgradeServiceTests.swift
//  BalizinhaTests
//
//  Created by Bobby Ren on 4/8/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import XCTest
@testable import Panna

class UpgradeServiceTests: XCTestCase {
    
    let defaults = UserDefaults()
    let interval: TimeInterval = 60
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        defaults.set(nil, forKey: "softUpgradeLastViewTimestamp")
        defaults.set(false, forKey: "neverShowSoftUpgrade")
        defaults.synchronize()
    }
    
    func testVersionUpgrades() {
        var currentVersion = "0.7.4"
        var newestVersion = "0.7.5"
        XCTAssertTrue(UpgradeService(currentVersion: currentVersion, newestVersion: newestVersion, upgradeInterval: interval, defaults: defaults).shouldShowSoftUpgrade)

        currentVersion = "0.7.9"
        newestVersion = "0.8.0"
        XCTAssertTrue(UpgradeService(currentVersion: currentVersion, newestVersion: newestVersion, upgradeInterval: interval, defaults: defaults).shouldShowSoftUpgrade)

        currentVersion = "0.7.9"
        newestVersion = "1.0.0"
        XCTAssertTrue(UpgradeService(currentVersion: currentVersion, newestVersion: newestVersion, upgradeInterval: interval, defaults: defaults).shouldShowSoftUpgrade)
    }
    
    func notWorking_testUpgrade10() {
        // TODO: this fails 
        let currentVersion = "0.7.9"
        let newestVersion = "0.7.10"
        XCTAssertTrue(UpgradeService(currentVersion: currentVersion, newestVersion: newestVersion, upgradeInterval: interval, defaults: defaults).shouldShowSoftUpgrade)
    }

    func testVersionDoesNotUpgrade() {
        var currentVersion = "0.7.5"
        var newestVersion = "0.7.5"
        XCTAssertFalse(UpgradeService(currentVersion: currentVersion, newestVersion: newestVersion, upgradeInterval: interval, defaults: defaults).shouldShowSoftUpgrade)

        currentVersion = "0.8.1"
        newestVersion = "0.8.0"
        XCTAssertFalse(UpgradeService(currentVersion: currentVersion, newestVersion: newestVersion, upgradeInterval: interval, defaults: defaults).shouldShowSoftUpgrade)
    }

    func testTimeElapsed() {
        defaults.set(Date() - interval, forKey: "softUpgradeLastViewTimestamp")
        defaults.synchronize()
    }
    
    func testDismissInterval() {
        let currentVersion = "0.7.4"
        let newestVersion = "0.7.5"
        let service = UpgradeService(currentVersion: currentVersion, newestVersion: newestVersion, upgradeInterval: interval, defaults: defaults)

        defaults.set(Date() - interval / 2, forKey: "softUpgradeLastViewTimestamp")
        defaults.synchronize()
        XCTAssertFalse(service.softUpgradeTimeElapsed)

        defaults.set(Date() - interval * 2, forKey: "softUpgradeLastViewTimestamp")
        defaults.synchronize()
        XCTAssertTrue(service.softUpgradeTimeElapsed)
    }

    func testNeverShowSoftUpgrade() {
        let currentVersion = "0.7.4"
        let newestVersion = "0.7.5"
        let service = UpgradeService(currentVersion: currentVersion, newestVersion: newestVersion, upgradeInterval: interval, defaults: defaults)
        
        XCTAssertFalse(service.neverShowSoftUpgrade)
        defaults.set(true, forKey: "neverShowSoftUpgrade")
        XCTAssertTrue(service.neverShowSoftUpgrade)
    }
    
    func testSoftUpgradeDismissedFunction() {
        let currentVersion = "0.7.4"
        let newestVersion = "0.7.5"
        let service = UpgradeService(currentVersion: currentVersion, newestVersion: newestVersion, upgradeInterval: interval, defaults: defaults)
        
        XCTAssertTrue(service.shouldShowSoftUpgrade)
        service.softUpgradeDismissed(neverShowAgain: false)
        XCTAssertFalse(service.shouldShowSoftUpgrade)
        
        // simulate time passing
        defaults.set(Date() - interval * 2, forKey: "softUpgradeLastViewTimestamp")
        XCTAssertTrue(service.shouldShowSoftUpgrade)
        
        // simulate the Never show again option
        service.softUpgradeDismissed(neverShowAgain: true)
        XCTAssertFalse(service.shouldShowSoftUpgrade)
    }
}
