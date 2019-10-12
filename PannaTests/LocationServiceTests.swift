//
//  LocationServiceTests.swift
//  PannaTests
//
//  Created by Bobby Ren on 10/12/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import XCTest
import CoreLocation
@testable import Panna

class LocationServiceTests: XCTestCase {

    var service: LocationService!
    var locationManager: MockLocationProvider!

    override func setUp() {
        locationManager = MockLocationProvider()
        locationManager.mockAuthorizationStatus = .alwaysInUse
        locationManager.mockLocation = CLLocation(latitude: 75, longitude: -122)

        service = LocationService(provider: locationManager)
    }

    override func tearDown() {
        service = nil
    }

    func testExample() {
    }
}
