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
                let name = place.name ?? ""
                let street = place.addressDictionary?["Street"] as? String
                let city = place.addressDictionary?["City"] as? String
                let state = place.addressDictionary?["State"] as? String
                self.labelPlaceName.text = "\(name)\n\(street ?? "") \(city ?? "") \(state ?? "")"
                self.name = name
                self.street = street
                self.city = city
                self.state = state
                
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
        LocationService.shared.findPlace(for: location) { [weak self] (place) in
            var name: String?
            var street: String?
            var city: String?
            var state: String?
            guard let lines = place?.lines else { return }
            print("Address \(lines)")
            if let sublocality = place?.subLocality {
                name = sublocality
            }
            if lines.count > 0 {
                street = lines[0]
            }
            if lines.count > 1 {
                city = lines[1]
            }
            if lines.count > 2 {
                state = lines[2]
            }
            self?.labelPlaceName.text = "\(street ?? "") \(city ?? "") \(state ?? "")"
            self?.updatedPlace = place
            self?.name = name
            self?.street = street
            self?.city = city
            self?.state = state
        }
    }
}
