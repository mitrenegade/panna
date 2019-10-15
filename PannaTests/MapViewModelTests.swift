//
//  MapViewModelTests.swift
//  PannaTests
//
//  Created by Bobby Ren on 10/14/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import XCTest
import CoreLocation
@testable import Balizinha

class MapViewModelTests: XCTestCase {

    var locationService: MockLocationService!
    var settingsService: MockSettingsService!

    var viewModel: MapViewModel!
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        locationService = MockLocationService()
        
        settingsService = MockSettingsService()

        viewModel = MapViewModel(settingsService: settingsService, locationService: locationService)
    }

    func testShouldShowMapWithSettingsOnAndLocation() {
        settingsService.mockSettings = [SettingsService.SettingsKey.maps: true]
        let location = CLLocation(latitude: 75, longitude: -122)
        locationService.mockLocationState = .located(location)
        XCTAssertTrue(viewModel.shouldShowMap)
    }

    func testShouldNotShowMapWithSettingsOffAndLocation() {
        settingsService.mockSettings = [SettingsService.SettingsKey.maps: false]
        let location = CLLocation(latitude: 75, longitude: -122)
        locationService.mockLocationState = .located(location)
        XCTAssertFalse(viewModel.shouldShowMap)
    }
    
    func testShouldShowMapWithSettingsOnAndVerifiedCity() {
        settingsService.mockSettings = [SettingsService.SettingsKey.maps: true]
        locationService.mockLocationState = .noLocation
        let city = City(key: "123", dict: ["name": "abc", "verified": true])
        locationService.mockPlayerCity = city
        XCTAssertTrue(viewModel.shouldShowMap)
    }

    func testShouldNotShowMapWithSettingsOnAndUnverifiedCity() {
        settingsService.mockSettings = [SettingsService.SettingsKey.maps: true]
        locationService.mockLocationState = .noLocation
        let city = City(key: "123", dict: ["name": "abc", "verified": false])
        locationService.mockPlayerCity = city
        XCTAssertFalse(viewModel.shouldShowMap)
    }

    func testShouldNotShowMapWithNoLocationOrCity() {
        settingsService.mockSettings = [SettingsService.SettingsKey.maps: true]
        locationService.mockLocationState = .noLocation
        XCTAssertFalse(viewModel.shouldShowMap)
    }

}
