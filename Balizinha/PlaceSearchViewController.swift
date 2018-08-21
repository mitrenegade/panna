//
//  PlaceSearchViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 11/1/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import MapKit
import RxSwift

protocol PlaceSelectDelegate: class {
    func didSelectPlace(name: String?, street: String?, city: String?, state: String?, location: CLLocationCoordinate2D?)
}

class PlaceSearchViewController: UIViewController {
    var searchController: UISearchController?
    @IBOutlet weak var mapView: MKMapView!
    var selectedPlace:MKPlacemark? = nil
    var refinedCoordinates: CLLocationCoordinate2D?
    
    weak var delegate: PlaceSelectDelegate?
    fileprivate var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupSearch()
        
        let button = UIButton(type: .custom)
        button.setTitle("Back", for: .normal)
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        let cancelButton = UIBarButtonItem(customView: button)
        self.navigationItem.leftBarButtonItem = cancelButton

        let button2 = UIButton(type: .custom)
        button2.setTitle("Save", for: .normal)
        button2.addTarget(self, action: #selector(selectLocation), for: .touchUpInside)
        let saveButton = UIBarButtonItem(customView: button2)
        self.navigationItem.rightBarButtonItem = saveButton
    }
    
    private lazy var __once: () = {
        LocationService.shared.startLocation(from: self)
        LocationService.shared.observedLocation.asObservable().subscribe(onNext: { [weak self] (state) in
            switch state {
            case .located(let location):
                self?.first = false
                self?.centerMapOnLocation(location: location)
                self?.disposeBag = DisposeBag()
            default:
                print("still locating")
            }
        }).disposed(by: disposeBag)
    }()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let _ = __once
    }
    
    @objc func cancel() {
        self.navigationController?.popViewController(animated: true)
    }
    
    fileprivate func setupSearch() {
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "PlaceResultsViewController") as! PlaceResultsViewController
        locationSearchTable.mapView = mapView
        locationSearchTable.delegate = self
        searchController = UISearchController(searchResultsController: locationSearchTable)
        searchController?.searchResultsUpdater = locationSearchTable
        searchController?.delegate = self
        
        let searchBar = searchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for locations"
        searchBar.showsCancelButton = false
        navigationItem.titleView = searchBar
        
        let keyboardNextButtonView = UIToolbar()
        keyboardNextButtonView.sizeToFit()
        keyboardNextButtonView.barStyle = UIBarStyle.black
        keyboardNextButtonView.isTranslucent = true
        keyboardNextButtonView.tintColor = UIColor.white
        let button: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.done, target: self, action: #selector(cancelSearch))
        let flex: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        keyboardNextButtonView.setItems([flex, button], animated: true)
        searchBar.inputAccessoryView = keyboardNextButtonView
        
        searchController?.hidesNavigationBarDuringPresentation = false
        searchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
    }
    
    var first: Bool = true
    func centerMapOnLocation(location: CLLocation) {
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    @objc func selectLocation() {
        guard let place = selectedPlace else { return }
        var name = place.name
        var street = place.addressDictionary?["Street"] as? String
        let city = place.addressDictionary?["City"] as? String
        let state = place.addressDictionary?["State"] as? String
        let coordinate: CLLocationCoordinate2D = refinedCoordinates ?? place.coordinate
        if let refined = refinedCoordinates {
            let loc1 = CLLocation(latitude: refined.latitude, longitude: refined.longitude)
            let loc2 = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            if loc1.distance(from: loc2) > 500 { // more than 500 meters away
                name = city ?? state
                street = nil
            }
        }
        print("selected placemark \(name), \(street), \(city), \(state), \(String(describing: coordinate))")

        delegate?.didSelectPlace(name: name, street: street, city: city, state: state, location: coordinate)
    }
    
    @objc fileprivate func cancelSearch() {
        searchController?.searchBar.resignFirstResponder()
    }
}

extension PlaceSearchViewController: UISearchControllerDelegate {
    func didPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.showsCancelButton = false
    }
}

extension PlaceSearchViewController: MKMapViewDelegate {
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        if first, let location = LocationService.shared.lastLocation {
            centerMapOnLocation(location: location)
            first = false
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if let placemark = selectedPlace {
            let mapCenter = mapView.centerCoordinate
            print("mapview: region changed to \(mapCenter)")

            // update annotation based on map center
            mapView.removeAnnotations(mapView.annotations)
            let annotation = MKPointAnnotation()
            annotation.coordinate = mapCenter
            annotation.title = placemark.name
            if let city = placemark.locality,
                let state = placemark.administrativeArea {
                annotation.subtitle = "\(city) \(state)"
            }
            mapView.addAnnotation(annotation)
            
            refinedCoordinates = mapCenter
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let location = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        //print("mapview: user location changed to \(location)")
        if first {
            first = false
            centerMapOnLocation(location: location)
        }
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

extension PlaceSearchViewController: PlaceResultsDelegate {
    func didSelectPlace(placemark:MKPlacemark){
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
        var span = MKCoordinateSpanMake(0.05, 0.05)
        if mapView.region.span.latitudeDelta < 0.05 || mapView.region.span.longitudeDelta < 0.05 {
            span = mapView.region.span
        }
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
    }
}
