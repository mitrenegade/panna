//
//  PlaceSearchViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 11/1/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import MapKit

class PlaceSearchViewController: UIViewController {

    var searchController: UISearchController?
    @IBOutlet weak var mapView: MKMapView? = nil

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
        var span = mapView?.region.span ?? MKCoordinateSpanMake(0.05, 0.05)
        if first {
            first = false
            span = MKCoordinateSpanMake(0.05, 0.05)
        }
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        mapView?.setRegion(region, animated: true)
    }
}

extension PlaceSearchViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("mapview: region changed with span \(mapView.region.span)")
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("mapview: user location changed")
        let location = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        centerMapOnLocation(location: location)
    }
}
