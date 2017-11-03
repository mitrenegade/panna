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
    var annotations: [String: MKAnnotation] = [String:MKAnnotation]()
    
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
    
    var first: Bool = true
    func centerMapOnLocation(location: CLLocation) {
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    override func reloadData() {
        super.reloadData()
        for event in self.allEvents {
            self.addAnnotation(for: event)
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        if first, let location = LocationService.shared.currentLocation {
            centerMapOnLocation(location: location)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("mapview: region changed ")
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let location = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        print("mapview: user location changed to \(location)")
        if first {
            first = false
            centerMapOnLocation(location: location)
        }
    }
}

// MARK: - Annotations
extension MapViewController {
    func addAnnotation(for event: Event) {
        guard let lat = event.lat, let lon = event.lon else { return }
        if let oldAnnotation = annotations[event.id] {
            mapView.removeAnnotations([oldAnnotation])
        }
        
        let annotation = MKPointAnnotation()
        let coordinate = CLLocationCoordinate2DMake(lat, lon)
        annotation.coordinate = coordinate
        annotation.title = event.name
        annotation.subtitle = event.locationString
        mapView.addAnnotation(annotation)
    }
}
