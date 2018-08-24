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

protocol PlaceSelectDelegate: class {
    func didSelectPlace(name: String?, street: String?, city: String?, state: String?, location: CLLocationCoordinate2D?)
}

class PlaceSearchViewController: UIViewController {
    var searchController: UISearchController?
    weak var delegate: PlaceSelectDelegate?
    
    weak var pinpointController: PinpointViewController?
    var currentEvent: Balizinha.Event?
    
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
        // user saved the location poinpointed on map
        delegate?.didSelectPlace(name: pinpointController?.name, street: pinpointController?.street, city: pinpointController?.city, state: pinpointController?.state, location: pinpointController?.currentLocation)
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

extension PlaceSearchViewController: PlaceResultsDelegate {
    // user selected a place from search results
    func didSelectPlace(placemark:MKPlacemark){
        pinpointController?.searchPlace = placemark
    }
}



