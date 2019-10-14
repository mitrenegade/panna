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
        
        cityService = MockService.mockCityService()
        playerService = PlayerService()

        service = LocationService(provider: locationManager, playerService: playerService, cityService: cityService)
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        service = nil
        disposeBag = nil
    }

    func testLocationServiceLoadsPlayerCityWhenLoggedIn() {
        let player = Player(key: "abc", dict: ["name": "John", "cityId": "123"])
        let expectation = XCTestExpectation(description: "Service should load player city")
        service.playerCity
            .asObservable()
            .filterNil()
            .take(1)
            .subscribe(onNext: { (city) in
                expectation.fulfill()
            }).disposed(by: self.disposeBag)
        playerService.current.value = player // trigger city search
        wait(for: [expectation], timeout: 1)
    }

    func testUsesCityForLocationIfPlayerLocationDoesNotExist() {
        let player = Player(key: "abc", dict: ["name": "John", "cityId": "123"])
        playerService.current.value = player // trigger city search
        let expectationCity = XCTestExpectation(description: "Observable location should first return player city's location")
        service.observableLocation
            .filterNil()
            .take(1)
            .subscribe(onNext: { (location) in
                // TODO: lat = 75, lon = -122
                expectationCity.fulfill()
            }).disposed(by: self.disposeBag)

        let loc = CLLocation(latitude: 75.1, longitude: -122.1)
        locationManager.mockLocation = loc
        let expectationLocationManager = XCTestExpectation(description: "Observable location should return location from LocationProvider")
        service.observableLocation
            .filterNil()
            .take(1)
            .subscribe(onNext: { (location) in
                // TODO: lat = 75.1, lon = -122.1
                expectationLocationManager.fulfill()
            }).disposed(by: self.disposeBag)
        
        wait(for: [expectationCity, expectationLocationManager], timeout: 1)
    }
}
