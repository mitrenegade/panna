
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
    
    var tutorialController: TutorialViewController?
    var tutorialView: UIView?
    
    // MARK: filtered events
    var filteredEventIds: [String] = []
    var filteredEvents: [Event] {
        return allEvents.filter({ (event) -> Bool in
            return filteredEventIds.contains(event.id)
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if PlayerService.isAnonymous, SettingsService.showPreview {
            navigationItem.title = "Balizinha"
            
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign in", style: .done, target: self, action: #selector(didClickProfile(_:)))
        }
    }
    
    fileprivate lazy var __once: () = {
        LocationService.shared.startLocation(from: self)
    }()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        var showedTutorial: Bool = false
        if PlayerService.isAnonymous {
            showedTutorial = showTutorialIfNeeded()
        }
        if !showedTutorial {
            // start location
            let _ = __once
        }
    }
    
    var first: Bool = true
    func centerMapOnLocation(location: CLLocation) {
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    override func reloadData() {
        super.reloadData()
        for event in allEvents {
            addAnnotation(for: event)
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
        filteredEventIds.removeAll()
        filteredEventIds.append(eventId)
        tableView.reloadData()
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        filteredEventIds.removeAll()
        tableView.reloadData()
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
            if allEvents.count == 0 {
                return 1
            }
            return allEvents.count
        }
        return filteredEvents.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if filteredEventIds.isEmpty && allEvents.isEmpty {
            return tableView.dequeueReusableCell(withIdentifier: "NoEventsCell", for: indexPath)
        }
        
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
            guard indexPath.row < allEvents.count else { return }
            event = allEvents[indexPath.row]
        }
        else {
            guard indexPath.row < filteredEvents.count else { return }
            event = filteredEvents[indexPath.row]
        }
        performSegue(withIdentifier: "toEventDetails", sender: event)
    }
}

extension MapViewController: TutorialDelegate {
    fileprivate var shouldShowTutorial: Bool {
        if AIRPLANE_MODE && TESTING {
            return true
        }
        if UserDefaults.standard.bool(forKey: "showedTutorial") == true {
            return false
        }
        if tutorialController != nil {
            return false
        }
        return true
    }
    func showTutorialIfNeeded() -> Bool {
        guard shouldShowTutorial else { return false }
        guard let controller = UIStoryboard(name: "Tutorial", bundle: nil).instantiateInitialViewController() as? TutorialViewController else { return false }
        tutorialController = controller
        
        present(controller, animated: true, completion: nil)
        
        controller.delegate = self
        LoggingService.shared.log(event: LoggingEvent.PreviewTutorialClicked, info: nil)

        return true
    }
    
    func didTapTutorial() {
        // do nothing on tap
    }
    
    func didClickNext() {
        LoggingService.shared.log(event: LoggingEvent.PreviewTutorialClicked, info: nil)
        
        dismiss(animated: true, completion: nil)
        tutorialController = nil
        UserDefaults.standard.set(true, forKey: "showedTutorial")
        
        // only prompt for location after dismissing tutorial
        let _ = __once
    }
}

// MARK: - Preview
extension MapViewController {
    // EventCellDelegate
    override func previewEvent(_ event: Event) {
        print("Preview")
        performSegue(withIdentifier: "toEventDetails", sender: event)
        LoggingService.shared.log(event: LoggingEvent.PreviewEventClicked, info: nil)
    }
    
    // signup
    @objc func didClickProfile(_ sender: Any) {
        print("Create profile")
        SplashViewController.shared?.goToSignupLogin()
        LoggingService.shared.log(event: LoggingEvent.PreviewSignupClicked, info: nil)
    }
}
