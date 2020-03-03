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

class PinpointViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var labelPlaceName: UILabel!
    
    var existingVenue: Venue?
    
    private (set) var name: String?
    private (set) var street: String?
    private (set) var city: String?
    private (set) var state: String?
    private (set) var lat: Double?
    private (set) var lon: Double?
    fileprivate var nameLocked: Bool = false
    
    @IBOutlet weak var buttonEdit: UIButton!
    
    fileprivate var externalSource: Bool = true
    var searchPlace: MKPlacemark? {
        didSet {
            if let place = searchPlace {
                externalSource = true // skips reverse geocode
                currentLocation = place.coordinate
                
                LocationService.shared.parseMKPlace(place, completion: { [weak self] (name, street, city, state) in
                    self?.name = name
                    self?.street = street
                    self?.city = city
                    self?.state = state
                    self?.lat = place.coordinate.latitude
                    self?.lon = place.coordinate.longitude
                    self?.refreshLabel()
                })
            }
        }
    }
    var currentLocation: CLLocationCoordinate2D? {
        didSet {
            if let location = currentLocation {
                var span = mapView.region.span
                if externalSource {
                    span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                }
                let region = MKCoordinateRegion(center: location, span: span)
                mapView.setRegion(region, animated: true)
            }
        }
    }
    
    @IBOutlet weak var pinView: UIView!
    
    fileprivate var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LocationService.shared.startLocation(from: self)
        
        if let existingVenue = existingVenue {
            name = existingVenue.name
            street = existingVenue.street
            city = existingVenue.city
            state = existingVenue.state
            lat = existingVenue.lat
            lon = existingVenue.lon
            
            // venue was sent in from event
            refreshLabel()
            
            if let lat = existingVenue.lat, let lon = existingVenue.lon {
                let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                currentLocation = location
            }
            externalSource = true
            nameLocked = true
        } else {
            LocationService.shared.observableLocation
                .filterNil()
                .take(1)
                .subscribe(onNext: { [weak self] (location) in
                #if targetEnvironment(simulator)
                self?.externalSource = false // trigger a geocode in simulator. not needed on device
                #endif
                self?.currentLocation = location.coordinate
            }).disposed(by: disposeBag)
        }
    }
    
    private func refreshLabel() {
        var text: String = ""
        if let name = name {
            text = "\(name)\n"
        }
        if let street = street, street != name {
            text = "\(text)\(street)\n"
        }
        if let city = city, let state = state {
            text = "\(text)\(city), \(state)"
        } else if let city = city {
            text = "\(text)\(city)"
        } else if let state = state {
            text = "\(text)\(state)"
        }
        labelPlaceName.text = text
    }
}

extension PinpointViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        guard !externalSource else {
            externalSource = false
            return
        }
        
        let mapCenter = mapView.centerCoordinate
        currentLocation = mapCenter
        
        doGeocode()
        
        LoggingService.shared.log(event: .DragVenueMap, info: nil)
    }
    
    fileprivate func doGeocode() {
        guard let location = currentLocation else { return }
        LocationService.shared.findApplePlace(for: location) {[weak self] (place) in
            guard let place = place else { return }
            LocationService.shared.parseCLPlace(place, completion: { [weak self] (newName, street, city, state) in
                if self?.nameLocked != true {
                    self?.name = newName
                }
                self?.street = street
                self?.city = city
                self?.state = state
                self?.lat = location.latitude
                self?.lon = location.longitude
                self?.refreshLabel()
            })
        }
    }
    
    @IBAction func didClickEdit(_ sender: Any) {
        /*
        let alert = UIAlertController(title: "Venue Options", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Edit name", style: .default, handler: { (action) in
            self.editName()
        }))
        let title = nameLocked ? "Unlock name" : "Lock name"
        alert.addAction(UIAlertAction(title: title, style: .default, handler: { (action) in
            self.nameLocked = !self.nameLocked
            LoggingService.shared.log(event: .LockVenueName, info: ["locked": self.nameLocked])
        }))
        alert.addAction(UIAlertAction(title: "Close", style: .cancel) { (action) in
        })
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad)
        {
            alert.popoverPresentationController?.sourceView = self.view
            alert.popoverPresentationController?.sourceRect = buttonEdit.frame
        }
        present(alert, animated: true, completion: nil)
        */
        performSegue(withIdentifier: "toEditVenue", sender: nil)
    }
    
    fileprivate func editName() {
        let alert = UIAlertController(title: "What should this venue be called?", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter venue name"
            textField.text = self.name
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if let textField = alert.textFields?[0], let name = textField.text {
                print("Manually changing name to \(name)")
                self.name = name
                self.refreshLabel()
                LoggingService.shared.log(event: .EditVenueName, info: ["saved": true, "name": name])
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            LoggingService.shared.log(event: .EditVenueName, info: ["saved": false])
        }))
        self.present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toEditVenue", let controller = segue.destination as? VenueEditViewController {
            controller.venue = existingVenue
        }
    }
}
