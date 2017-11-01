//
//  MapViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 1/22/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class MapViewController: EventsViewController {
    // Data
    
    // MARK: MapView
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    private lazy var __once: () = {
        LocationService.shared.startLocation(from: self)
    }()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let _ = __once
    }
    
    var currentRadius: CLLocationDistance = 1000
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  currentRadius, currentRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        currentRadius = mapView.currentRadius
        print("mapview: region changed with radius \(currentRadius)")
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("mapview: user location changed")
        let location = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        centerMapOnLocation(location: location)
    }
}

extension MKMapView {
    
    func topCenterCoordinate() -> CLLocationCoordinate2D {
        return self.convert(CGPoint(x: self.frame.size.width / 2.0, y: 0), toCoordinateFrom: self)
    }
    
    var currentRadius: Double {
        let centerLocation = CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
        let topCenterCoordinate = self.topCenterCoordinate()
        let topCenterLocation = CLLocation(latitude: topCenterCoordinate.latitude, longitude: topCenterCoordinate.longitude)
        return centerLocation.distance(from: topCenterLocation)
    }
    
}
