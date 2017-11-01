//
//  PlaceSearchViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 11/1/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import MapKit

protocol MapSearchDelegate {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class PlaceSearchViewController: UIViewController {

    var searchController: UISearchController?
    @IBOutlet weak var mapView: MKMapView!
    var selectedPlace:MKPlacemark? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupSearch()
        
        self.navigationItem.leftBarButtonItem?.title = nil
    }
    
    private lazy var __once: () = {
        LocationService.shared.startLocation(from: self)
    }()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let _ = __once
    }
    
    fileprivate func setupSearch() {
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "PlaceResultsViewController") as! PlaceResultsViewController
        locationSearchTable.mapView = mapView
        locationSearchTable.mapSearchDelegate = self
        searchController = UISearchController(searchResultsController: locationSearchTable)
        searchController?.searchResultsUpdater = locationSearchTable
        
        let searchBar = searchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for locations"
        navigationItem.titleView = searchBar
        
        searchController?.hidesNavigationBarDuringPresentation = false
        searchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
    }
    
    fileprivate var first: Bool = true
    func centerMapOnLocation(location: CLLocation) {
        var span = mapView.region.span
        if first {
            first = false
            span = MKCoordinateSpanMake(0.05, 0.05)
        }
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    func selectLocation() {
        print("selected placemark \(selectedPlace)")
    }
}

extension PlaceSearchViewController: MKMapViewDelegate {
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        if let location = LocationService.shared.currentLocation {
            centerMapOnLocation(location: location)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("mapview: region changed with span \(mapView.region.span)")
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("mapview: user location changed")
        let location = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        centerMapOnLocation(location: location)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.pinTintColor = UIColor.orange
        pinView?.canShowCallout = true
        let button = UIButton(type: .custom)
        button.setTitle("Go", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        button.layer.cornerRadius = button.frame.size.width / 2
        button.backgroundColor = UIColor.blue
        button.addTarget(self, action: #selector(PlaceSearchViewController.selectLocation), for: .touchUpInside)
        pinView?.leftCalloutAccessoryView = button
        return pinView
    }
}

extension PlaceSearchViewController: MapSearchDelegate {
    func dropPinZoomIn(placemark:MKPlacemark){
        // cache the pin
        selectedPlace = placemark
        // clear existing pins
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
    }
}
