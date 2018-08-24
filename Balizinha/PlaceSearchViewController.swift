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
import Balizinha
import GoogleMaps

protocol PlaceSelectDelegate: class {
    func didSelectPlace(name: String?, street: String?, city: String?, state: String?, location: CLLocationCoordinate2D?)
}

class PlaceSearchViewController: UIViewController {
    var searchController: UISearchController?
    weak var delegate: PlaceSelectDelegate?
    
    weak var pinpointController: PinpointViewController?
    var currentEvent: Balizinha.Event?
    
    var selectedPlace: MKPlacemark?

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
    
    @objc func cancel() {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedMap", let controller = segue.destination as? PinpointViewController {
            controller.currentEvent = currentEvent
            pinpointController = controller
        }
    }
}

extension PlaceSearchViewController {
    fileprivate func setupSearch() {
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "PlaceResultsViewController") as! PlaceResultsViewController
        locationSearchTable.mapView = pinpointController?.mapView
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
    
    @objc func selectLocation() {
        if let place = pinpointController?.updatedPlace {
            handleGooglePlace(place)
        } else if let place = selectedPlace {
            handleApplePlace(place)
        }
    }
    
    @objc fileprivate func cancelSearch() {
        searchController?.searchBar.resignFirstResponder()
    }
    
    fileprivate func handleGooglePlace(_ place: GMSAddress) {
        let name = place.locality
        var street: String?
        var city: String?
        var state: String?
        let lines = place.lines ?? []
        if lines.count > 0 {
            street = lines[0]
        }
        if lines.count > 1 {
            city = lines[1]
        }
        if lines.count > 2 {
            state = lines[2]
        }
        let coordinate = place.coordinate
        delegate?.didSelectPlace(name: name, street: street, city: city, state: state, location: coordinate)
    }
    
    fileprivate func handleApplePlace(_ place: MKPlacemark) {
        let name = place.name
        let street = place.addressDictionary?["Street"] as? String
        let city = place.addressDictionary?["City"] as? String
        let state = place.addressDictionary?["State"] as? String
        let coordinate: CLLocationCoordinate2D = place.coordinate
        print("selected placemark \(name), \(street), \(city), \(state), \(String(describing: coordinate))")
        delegate?.didSelectPlace(name: name, street: street, city: city, state: state, location: coordinate)
    }
}

extension PlaceSearchViewController: UISearchControllerDelegate {
    func didPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.showsCancelButton = false
    }
}

extension PlaceSearchViewController: PlaceResultsDelegate {
    func didSelectPlace(placemark:MKPlacemark){
        selectedPlace = placemark
        pinpointController?.searchPlace = placemark
    }
}



