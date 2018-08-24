//
//  PinpointViewController.swift
//  Panna
//
//  Created by Bobby Ren on 8/23/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import MapKit
import RxSwift
import Balizinha
import GoogleMaps
import MapKit

class PinpointViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var labelPlaceName: UILabel!

    var updatedPlace: GMSAddress?
    var name: String?
    var street: String?
    var city: String?
    var state: String?
    
    let queue = DispatchQueue(label: "geocode", qos: DispatchQoS.background)
    
    var externalSource: Bool = true
    var searchPlace: MKPlacemark? {
        didSet {
            if let place = searchPlace {
                updatedPlace = nil
                parseMKPlace(place)
                
                externalSource = true
                currentLocation = place.coordinate
            }
        }
    }
    var currentLocation: CLLocationCoordinate2D? {
        didSet {
            if let location = currentLocation {
                var span = MKCoordinateSpanMake(0.05, 0.05)
                if mapView.region.span.latitudeDelta < 0.05 || mapView.region.span.longitudeDelta < 0.05 {
                    span = mapView.region.span
                }
                let region = MKCoordinateRegionMake(location, span)
                mapView.setRegion(region, animated: true)
            }
        }
    }
    
    @IBOutlet weak var pinView: UIView!
    
    var currentEvent: Balizinha.Event?
    fileprivate var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        LocationService.shared.startLocation(from: self)
        if let event = currentEvent, let lat = event.lat, let lon = event.lon {
            let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            currentLocation = location
        } else {
            LocationService.shared.observedLocation.asObservable().subscribe(onNext: { [weak self] (state) in
                switch state {
                case .located(let location):
                    self?.externalSource = false // trigger a geocode
                    self?.currentLocation = location.coordinate
                    self?.disposeBag = DisposeBag()
                default:
                    print("still locating")
                }
            }).disposed(by: disposeBag)
        }
    }
}
extension PinpointViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        guard !externalSource else {
            externalSource = false
            return
        }
        
        let mapCenter = mapView.centerCoordinate
        print("mapview: region changed to \(mapCenter)")
        currentLocation = mapCenter
        
        doGeocode()
    }
    
    fileprivate func doGeocode() {
        guard let location = currentLocation else { return }
//        LocationService.shared.findGooglePlace(for: location) { [weak self] (place) in
//            self?.updatedPlace = place
//            self?.parseGMSAddress(place)
//            self?.labelPlaceName.text = "\(name ?? "")\n\(street ?? "") \(city ?? "") \(state ?? "")"
//        }
        LocationService.shared.findApplePlace(for: location) {[weak self] (place) in
            guard let place = place else { return }
            self?.parseCLPlace(place)
            self?.labelPlaceName.text = "\(self?.name ?? "")\n\(self?.street ?? ""), \(self?.city ?? ""), \(self?.state ?? "")"
        }
    }
    
    func parseGMSAddress(_ place: GMSAddress) {
        // handles places returned by GMSGeocoder (google)
        name = place.subLocality
        guard let lines = place.lines else { return }
        if lines.count > 0 {
            street = lines[0]
        }
        if lines.count > 1 {
            city = lines[1]
        }
        if lines.count > 2 {
            state = lines[2]
        }
    }
    
    func parseMKPlace(_ place: MKPlacemark) {
        // handles places returned by MapKit
        name = place.name
        street = place.addressDictionary?["Street"] as? String
        city = place.addressDictionary?["City"] as? String
        state = place.addressDictionary?["State"] as? String
    }
    
    func parseCLPlace(_ place: CLPlacemark) {
        // handles places returned by CLGeocoder
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
    }
}
