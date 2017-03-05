//
//  LocationService.swift
//  Balizinha
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation
import CoreLocation

class LocationService: NSObject, CLLocationManagerDelegate {
    static let sharedInstance = LocationService()
    
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var lastLocation: CLLocation?

    func startLocation() {
        // location
        locationManager.delegate = self
        let loc: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        if loc == CLAuthorizationStatus.authorizedAlways || loc == CLAuthorizationStatus.authorizedWhenInUse{
            locationManager.startUpdatingLocation()
        }
        else if loc == CLAuthorizationStatus.denied {
            self.warnForLocationPermission()
        }
        else {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    // MARK: - CLLocationManagerDelegate
    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
        else if status == .denied {
            self.warnForLocationPermission()
            print("Authorization is not available")
        }
        else {
            print("status unknown")
        }
    }
    
    private func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first as CLLocation? {
            print("\(location)")
            if self.currentLocation == nil {
                // initiate search now
                self.currentLocation = location
            }
        }
    }

    // MARK: location
    func warnForLocationPermission() {
        let message: String = "BondVoyage needs GPS access to find activities near you. Please go to your phone settings to enable location access. Go there now?"
        
        let alert: UIAlertController = UIAlertController(title: "Could not access location", message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (action) -> Void in
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func warnForLocationAvailability() {
        let message: String = "BondVoyage needs an accurate location to find a match. Please make sure your phone can receive accurate location information."
        let alert: UIAlertController = UIAlertController(title: "Accurate location not found", message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Close", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    

}
