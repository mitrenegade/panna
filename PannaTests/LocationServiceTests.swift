//
//  LocationServiceTests.swift
//  PannaTests
//
//  Created by Bobby Ren on 10/12/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import XCTest
import CoreLocation
import RxSwift
import RxCocoa
@testable import Panna
@testable import Balizinha

class LocationServiceTests: XCTestCase {

    var service: LocationService!
    var locationManager: MockLocationProvider!
    var cityService: CityService!
    var playerService: PlayerService!
    var disposeBag: DisposeBag!

    override func setUp() {
        locationManager = MockLocationProvider()
        locationManager.mockAuthorizationStatus = .notDetermined
        locationManager.mockLocation = CLLocation(latitude: 75, longitude: -122)
        
        cityService = CityService()
        playerService = PlayerService()

        service = LocationService(provider: locationManager, playerService: playerService, cityService: cityService)
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        service = nil
        disposeBag = nil
    }

    func testLocationServiceLoadsPlayerCityWhenLoggedIn() {
        let expectation = XCTestExpectation(description: "Service should load player city")
        service.playerCity
            .asObservable()
            .filterNil()
            .take(1)
            .subscribe(onNext: { (city) in
                expectation.fulfill()
            }).disposed(by: self.disposeBag)
        wait(for: [expectation], timeout: 1)
    }

    func testLocationServiceLoadsPlayerCityIfPlayerExists() {
//        let expectation = XCTestExpectation(description: "Service should load player city")
//        service.getPlayerCity {
//            expectation.fulfill()
//        }
//        wait(for: [expectation], timeout: 1)
    }
    
    func testUsesCityForLocationIfPlayerLocationDoesNotExist() {
        
    }
}
