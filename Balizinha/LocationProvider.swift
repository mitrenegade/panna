//
//  LocationProvider.swift
//  Panna
//
//  Created by Bobby Ren on 10/12/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//
//  API layer for CLLocationManager

import CoreLocation

protocol LocationProvider {
    static func locationServicesEnabled() -> Bool
    static func authorizationStatus() -> CLAuthorizationStatus

    var delegate: CLLocationManagerDelegate? { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var allowsBackgroundLocationUpdates: Bool { get set }

    var location: CLLocation? { get }

    func requestWhenInUseAuthorization()
    func requestAlwaysAuthorization()

    func startUpdatingLocation()
    func stopUpdatingLocation()
    func requestLocation()

    func stopMonitoring(for region: CLRegion)
    func startMonitoring(for region: CLRegion)
}

extension CLLocationManager: LocationProvider {
    // no changes needed
}
