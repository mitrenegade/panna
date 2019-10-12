//
//  MockLocationProvider.swift
//  Panna
//
//  Created by Bobby Ren on 10/12/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import UIKit
import CoreLocation

class MockLocationProvider: NSObject, LocationProvider {
    var mockAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    var mockLocation: CLLocation?

    func locationServicesEnabled() -> Bool {
        return true
    }
    
    func authorizationStatus() -> CLAuthorizationStatus {
        return mockAuthorizationStatus
    }
    
    var delegate: CLLocationManagerDelegate?
    
    var desiredAccuracy: CLLocationAccuracy = 0.0
    
    var allowsBackgroundLocationUpdates: Bool = false
    
    var location: CLLocation?
    
    func requestWhenInUseAuthorization() {
        delegate?.locationManager?(CLLocationManager(), didChangeAuthorization: mockAuthorizationStatus)
    }
    
    func requestAlwaysAuthorization() {
        return
    }
    
    func startUpdatingLocation() {
        // TODO: return a location, on a clock?
        return
    }
    
    func stopUpdatingLocation() {
        return
    }
    
    func requestLocation() {
        // TODO: return a location
        return
    }
    
    func stopMonitoring(for region: CLRegion) {
        return
    }
    
    func startMonitoring(for region: CLRegion) {
        return
    }
}
