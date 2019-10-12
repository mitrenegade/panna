//
//  LocationServiceTests.swift
//  PannaTests
//
//  Created by Bobby Ren on 10/12/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import XCTest
import CoreLocation

class LocationServiceTests: XCTestCase {

    var service: LocationService!

    override func setUp() {
        service = MockLocationService()
        service.mockAuthorizationStatus = .alwaysInUse
        service.mockLocation = CLLocation(latitude: 75, longitude: -122)
    }

    override func tearDown() {
        service = nil
    }

    func testExample() {
    }
}
