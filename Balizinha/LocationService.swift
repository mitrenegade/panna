//
//  LocationService.swift
//  Balizinha
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import RxSwift
import MapKit
import Balizinha
import CoreLocation

enum LocationState {
    case denied
    case noLocation
    case located(CLLocation)
}
class LocationService: NSObject {
    static let shared = LocationService(provider: CLLocationManager())
    
    private (set) var locationManager: LocationProvider
    var locationState: Variable<LocationState> = Variable(.noLocation)
    var lastLocation: CLLocation?
    
    init(provider: LocationProvider) {
        locationManager = provider
    }

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
            locationState.value = .denied
        }
        else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    // MARK: location
    func warnForLocationPermission(from controller: UIViewController?) {
        guard DefaultsManager.shared.value(forKey: DefaultsKey.locationPermissionDeniedWarningShown.rawValue) as? Bool != true else {
            return
        }
        let message: String = "Balizina needs location access to find events near you. Please go to your phone settings to enable location access."
        
        let alert: UIAlertController = UIAlertController(title: "Could not access location", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Disable Location", style: .cancel, handler: {[weak self] action in
            // disable location popup for the future, and turn on global view
            DefaultsManager.shared.setValue(true, forKey: DefaultsKey.locationPermissionDeniedWarningShown.rawValue)
            DefaultsManager.shared.setValue(false, forKey: DefaultsKey.shouldFilterNearbyEvents.rawValue)
            
            // refresh map
            self?.notify(NotificationType.EventsChanged, object: nil, userInfo: nil)
            self?.notify(NotificationType.LocationOptionsChanged, object: nil, userInfo: nil)
        }))
        if let url = URL(string: UIApplication.openSettingsURLString) {
            alert.addAction(UIAlertAction(title: "Go to Settings", style: .default, handler: { (action) -> Void in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }))
        }
        if let controller = controller {
            controller.present(alert, animated: true, completion: nil)
        } else if let controller = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController {
            controller.present(alert, animated: true, completion: nil)
        }
    }
    
    func warnForLocationAvailability(from controller: UIViewController?) {
        let message: String = "Balizinha needs to pinpoint your location to find events. Please make sure your phone can receive accurate location information."
        let alert: UIAlertController = UIAlertController(title: "Accurate location not found", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
        if let controller = controller {
            controller.present(alert, animated: true, completion: nil)
        } else if let controller = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController {
            controller.present(alert, animated: true, completion: nil)
        }
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
            locationState.value = .denied
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
            return DefaultsManager.shared.value(forKey: DefaultsKey.shouldFilterNearbyEvents.rawValue) as? Bool ?? true
        }
        set {
            DefaultsManager.shared.setValue(newValue, forKey: DefaultsKey.shouldFilterNearbyEvents.rawValue)
            DefaultsManager.shared.setValue(false, forKey: DefaultsKey.locationPermissionDeniedWarningShown.rawValue)
        }
    }
}

// google maps utilities
typealias PlaceParseCompletion = ((_ name: String?, _ street: String?, _ city: String?, _ state: String?)->Void)
extension LocationService {
    
//    func findGooglePlace(for coordinate: CLLocationCoordinate2D, completion: ((_ place: GMSAddress?)->())?) {
//        let gms = GMSGeocoder()
//        gms.reverseGeocodeCoordinate(coordinate) { (responses, error) in
//            print("Response \(responses?.results()) error \(error)")
//            guard let addresses = responses?.results() else {
//                completion?(nil)
//                return
//            }
//            for address in addresses {
//                if address.subLocality != nil {
//                    completion?(address)
//                    return
//                }
//            }
//            
//            // no sublocality found
//            if let address = responses?.firstResult() {
//                completion?(address)
//            } else {
//                completion?(nil)
//            }
//        }
//    }
    
    func findApplePlace(for coordinate: CLLocationCoordinate2D, completion: ((_ place: CLPlacemark?) -> Void)?) {
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geoCoder.reverseGeocodeLocation(location) { (results, error) in
            guard let results = results else {
                completion?(nil)
                return
            }
            print("Placemarks \(results)")
            completion?(results.first)
        }
    }
    
//    func parseGMSAddress(_ place: GMSAddress, completion: PlaceParseCompletion?) {
//        // handles places returned by GMSGeocoder (google)
//        var name: String?
//        var street: String?
//        var city: String?
//        var state: String?
//        name = place.subLocality
//        guard let lines = place.lines else { return }
//        if lines.count > 0 {
//            street = lines[0]
//        }
//        if lines.count > 1 {
//            city = lines[1]
//        }
//        if lines.count > 2 {
//            state = lines[2]
//        }
//        completion?(name, street, city, state)
//    }
    
    func parseMKPlace(_ place: MKPlacemark, completion: PlaceParseCompletion?) {
        // handles places returned by MapKit
        var name: String?
        var street: String?
        var city: String?
        var state: String?
        name = place.name
        street = place.thoroughfare
        city = place.locality
        state = place.administrativeArea
        completion?(name, street, city, state)
    }
    
    func parseCLPlace(_ place: CLPlacemark, completion: PlaceParseCompletion?) {
        // handles places returned by CLGeocoder
        var name: String?
        var street: String?
        var city: String?
        var state: String?
        if #available(iOS 11.0, *) {
            let address = place.postalAddress
            name = place.name
            street = address?.street
            city = address?.city
            state = address?.state
        } else {
            // Fallback on earlier versions
            name = place.name
            street = place.thoroughfare
            city = place.locality
            state = place.administrativeArea
        }
        completion?(name, street, city, state)
    }
}
