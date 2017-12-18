//
//  LocationService.swift
//  Balizinha
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import RxSwift

enum LocationState {
    case noLocation
    case located(CLLocation)
}
class LocationService: NSObject {
    static let shared = LocationService()
    
    let locationManager = CLLocationManager()
    var locationState: Variable<LocationState> = Variable(.noLocation)
    var lastLocation: CLLocation?
    
    var observedLocation: Observable<LocationState> {
        return locationState.asObservable()
    }
    
    func startLocation(from controller: UIViewController?) {
        // location
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        let loc: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        if loc == CLAuthorizationStatus.authorizedAlways || loc == CLAuthorizationStatus.authorizedWhenInUse{
            locationManager.startUpdatingLocation()
        }
        else if loc == CLAuthorizationStatus.denied {
            self.warnForLocationPermission(from: controller)
        }
        else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    // MARK: location
    func warnForLocationPermission(from controller: UIViewController?) {
        guard UserDefaults.standard.bool(forKey: "locationPermissionDeniedWarningShown") != true else {
            return
        }
        let message: String = "Balizina needs location access to find events near you. Please go to your phone settings to enable location access."
        
        let alert: UIAlertController = UIAlertController(title: "Could not access location", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Disable Location", style: .cancel, handler: {[weak self] action in
            // disable location popup for the future, and turn on global view
            UserDefaults.standard.set(true, forKey: "locationPermissionDeniedWarningShown")
            UserDefaults.standard.set(false, forKey: "shouldFilterNearbyEvents")
            UserDefaults.standard.synchronize()
            
            // refresh map
            if #available(iOS 10.0, *) {
                NotificationService.shared.notify(NotificationType.EventsChanged, object: nil, userInfo: nil)
            } else {
                // Fallback on earlier versions
            }
        }))
        if let url = URL(string: UIApplicationOpenSettingsURLString) {
            alert.addAction(UIAlertAction(title: "Go to Settings", style: .default, handler: { (action) -> Void in
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    // Fallback on earlier versions
                    UIApplication.shared.openURL(url)
                }
            }))
        }
        controller?.present(alert, animated: true, completion: nil)
    }
    
    func warnForLocationAvailability(from controller: UIViewController?) {
        let message: String = "Balizinha needs to pinpoint your location to find events. Please make sure your phone can receive accurate location information."
        let alert: UIAlertController = UIAlertController(title: "Accurate location not found", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
        controller?.present(alert, animated: true, completion: nil)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            print("location status changed")
            locationManager.startUpdatingLocation()
        }
        else if status == .denied {
            warnForLocationPermission(from: nil)
            print("Authorization is not available")
        }
        else {
            print("status unknown")
        }
    }
    
    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first as CLLocation? {
            self.locationState.value = .located(location)
            lastLocation = location
        }
    }
}

extension LocationService {
    var shouldFilterNearbyEvents: Bool {
        get {
            // default is true for filtering nearby events
            return UserDefaults.standard.value(forKey: "shouldFilterNearbyEvents") as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "shouldFilterNearbyEvents")
        }
    }
}

