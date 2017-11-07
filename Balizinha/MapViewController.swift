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
    
    // MARK: filtered events
    var filteredEventIds: [String] = []
    var filteredEvents: [Event] {
        return self.allEvents.filter({ (event) -> Bool in
            return filteredEventIds.contains(event.id)
        })
    }
    
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
        
        annotations[event.id] = annotation
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        if first, let location = LocationService.shared.lastLocation {
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let selectedAnnotation = view.annotation else { return }
        var selectedId: String?
        for (eventId, annotation) in annotations {
            if annotation.title! == selectedAnnotation.title! && annotation.coordinate.latitude == selectedAnnotation.coordinate.latitude && annotation.coordinate.longitude == selectedAnnotation.coordinate.longitude {
                selectedId = eventId
                break
            }
        }
        guard let eventId = selectedId else { return }
        self.filteredEventIds.removeAll()
        self.filteredEventIds.append(eventId)
        self.tableView.reloadData()
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        self.filteredEventIds.removeAll()
        self.tableView.reloadData()
    }
}

// MARK: UITableViewDataSource, UITableViewDelegate
extension MapViewController {
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filteredEventIds.isEmpty {
            return allEvents.count
        }
        return filteredEvents.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : EventCell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventCell
        cell.delegate = self
        
        let event: Event
        if filteredEventIds.isEmpty {
            event = allEvents[indexPath.row]
        }
        else {
            event = filteredEvents[indexPath.row]
        }
        cell.setupWithEvent(event)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let event: Event
        if filteredEventIds.isEmpty {
            event = allEvents[indexPath.row]
        }
        else {
            event = filteredEvents[indexPath.row]
        }
        performSegue(withIdentifier: "toEventDetails", sender: event)
    }
}

