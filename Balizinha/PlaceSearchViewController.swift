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
    func didSelect(venue: Venue?)
}

class PlaceSearchViewController: UIViewController {
    var searchController: UISearchController?
    weak var delegate: PlaceSelectDelegate?
    
    weak var pinpointController: PinpointViewController?
    var currentVenue: Venue? // for editing a venue
    private let activityOverlay: ActivityIndicatorOverlay = ActivityIndicatorOverlay()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        view.addSubview(activityOverlay)
        setupSearch()
        
        let button = UIButton(type: .custom)
        button.setTitle("Back", for: .normal)
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        let cancelButton = UIBarButtonItem(customView: button)
        self.navigationItem.leftBarButtonItem = cancelButton
        
        let button2 = UIButton(type: .custom)
        button2.setTitle("Next", for: .normal)
        button2.addTarget(self, action: #selector(editNameAndPhoto), for: .touchUpInside)
        let saveButton = UIBarButtonItem(customView: button2)
        self.navigationItem.rightBarButtonItem = saveButton
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        activityOverlay.setup(frame: view.frame)
    }
    
    @objc func cancel() {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedMap", let controller = segue.destination as? PinpointViewController {
            controller.existingVenue = currentVenue
            pinpointController = controller
        } else if segue.identifier == "toVenueDetails", let controller = segue.destination as? VenueDetailsViewController {
            controller.existingVenue = currentVenue
            controller.name = pinpointController?.name
            controller.street = pinpointController?.street
            controller.city = pinpointController?.city
            controller.state = pinpointController?.state
            controller.lat = pinpointController?.lat
            controller.lon = pinpointController?.lon
            
            controller.delegate = self
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
        let button: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(cancelSearch))
        let flex: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        keyboardNextButtonView.setItems([flex, button], animated: true)
        searchBar.inputAccessoryView = keyboardNextButtonView
        
        searchController?.hidesNavigationBarDuringPresentation = false
        searchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
    }
    
    @objc func editNameAndPhoto() {
        performSegue(withIdentifier: "toVenueDetails", sender: nil)
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
        
        var info: [String: Any]?
        if let searchTerm = searchController!.searchBar.text {
            info = ["searchTerm": searchTerm]
        }
        LoggingService.shared.log(event: .SearchForVenue, info: info)
    }
}

extension PlaceSearchViewController: VenueDetailsDelegate {
    func didFinishUpdatingVenue(_ venue: Venue?) {
        delegate?.didSelect(venue: venue)
    }
}
