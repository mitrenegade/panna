//
//  MapViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 1/22/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase
import Balizinha

class MapViewController: EventsViewController {
    // Data
    var annotations: [String: MKAnnotation] = [String:MKAnnotation]()
    
    // MARK: MapView
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var constraintTableHeight: NSLayoutConstraint!
    var first: Bool = true

    var tutorialController: TutorialViewController?
    var tutorialView: UIView?
    
    let defaults: DefaultsProvider = DefaultsManager.shared

    // MARK: filtered events
    var filteredEventIds: [String] = []
    var filteredEvents: [Balizinha.Event] {
        return allEvents.filter({ (event) -> Bool in
            return filteredEventIds.contains(event.id)
        })
    }
    
    var viewModel: MapViewModel = MapViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if AuthService.isAnonymous, SettingsService.showPreview {
            navigationItem.title = "Panna"
            
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign in", style: .done, target: self, action: #selector(didClickSignUp(_:)))
        } else {
            let profileButton = UIButton(type: .custom)
            profileButton.setImage(UIImage.init(named: "hamburger4-square30")?.withRenderingMode(.alwaysTemplate), for: .normal)
            profileButton.addTarget(self, action: #selector(didClickProfile(_:)), for: .touchUpInside)
            profileButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: profileButton)
        }
        
        // start listening for users so anonymous/preview users can see player counts
        EventService.shared.listenForEventUsers {
            NotificationService.shared.notify(.EventsChanged, object: nil, userInfo: nil)
        }
        EventService.shared.featuredEvent.asObservable().filterNil().distinctUntilChanged().subscribe(onNext: { (event) in
            NotificationService.shared.notify(.EventsChanged, object: nil, userInfo: nil)
        }).disposed(by: disposeBag)
        
        // deeplink actions available from this controller
        self.listenFor(NotificationType.GoToAccountDeepLink, action: #selector(didClickProfile(_:)), object: nil)

        LocationService.shared.observableLocation
            .filterNil()
            .subscribe(onNext: {[weak self] location in
                self?.refreshMap(location)
            }).disposed(by: disposeBag)
    }
    
    fileprivate lazy var __once: () = {
        LocationService.shared.startLocation(from: self)
    }()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        var showedTutorial: Bool = false
        if AuthService.isAnonymous {
            showedTutorial = showTutorialIfNeeded()
        }
        if !showedTutorial && PlayerService.shared.current.value != nil {
            // start location
            let _ = __once
        }
        
        // user's first signup, needs to create profile
        if PlayerService.shared.needsToCreateProfile {
            PlayerService.shared.needsToCreateProfile = false
            goToCreateProfile()
        }
    }
    
    override func reloadData() {
        super.reloadData()
        for event in allEvents {
            addAnnotation(for: event)
        }
        
        refreshMap()
    }
    
    func refreshMap(_ location: CLLocation? = nil) {
        if viewModel.shouldShowMap {
            if let location = location {
                centerMapOnLocation(location: location, animated: true)
            }
            let count = allEvents.count
            if allEvents.isEmpty {
                // leave only 1 cell height on. the ratio is 3/7 of the frame height to start
                constraintTableHeight.constant = 60
                tableView.isScrollEnabled = false
            } else if count < 3 {
                constraintTableHeight.constant = 100.0 * CGFloat(count)
                tableView.isScrollEnabled = false
            } else {
                constraintTableHeight.constant = 100.0 * 2.5
                tableView.isScrollEnabled = true
            }
        } else {
            constraintTableHeight.constant = self.view.frame.size.height
        }
    }
    
    override func doFilter(_ events: [Balizinha.Event]) -> [Balizinha.Event] {
        // for mapView, do not show cancelled events
        let result = super.doFilter(events)
                          .filter { return !$0.isCancelled }
        return result
    }
}

extension MapViewController {
    func centerMapOnLocation(location: CLLocation, animated: Bool = true) {
        guard viewModel.shouldShowMap else { return }
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        mapView.setRegion(region, animated: animated)
    }
    
    func addAnnotation(for event: Balizinha.Event) {
        guard viewModel.shouldShowMap else { return }
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
        guard first else { return }
        switch LocationService.shared.locationState.value {
        case .located(let location):
            centerMapOnLocation(location: location, animated: false)
        default:
            break
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
            centerMapOnLocation(location: location, animated: false)
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

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }

        let identifier = "marker"
        var view: MKAnnotationView
        
        // 4
        if #available(iOS 11.0, *) {
            let marker = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            marker.glyphImage = UIImage(named: "location40")
            view = marker
        } else {
            view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView ?? MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: "location40")
        }
        view.annotation = annotation
        view.canShowCallout = true
        view.calloutOffset = CGPoint(x: -20, y: 20)
        return view
    }
}

extension MapViewController {
    // MARK: - First time user edit account
    @objc fileprivate func didClickProfile(_ sender: Any) {
        print("Go to Account")
        guard let controller = UIStoryboard(name: "Account", bundle: nil).instantiateViewController(withIdentifier: "AccountViewController") as? AccountViewController else { return }
        let nav = UINavigationController(rootViewController: controller)
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "iconClose30"), style: .plain, target: self, action: #selector(self.dismissProfile))
        present(nav, animated: true) {
        }
    }

    @objc fileprivate func dismissProfile() {
        dismiss(animated: true, completion: nil)
    }
    
    // FTUE
    fileprivate func goToCreateProfile() {
        guard let player = PlayerService.shared.current.value else { return }
        if let controller = UIStoryboard(name: "Account", bundle: nil).instantiateViewController(withIdentifier: "PlayerInfoViewController") as? PlayerInfoViewController {
            let nav = UINavigationController(rootViewController: controller)
            controller.player = player
            controller.isCreatingPlayer = true
            present(nav, animated: true, completion: nil)
        }
    }
}

// MARK: UITableViewDataSource, UITableViewDelegate
extension MapViewController {
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if allEvents.count == 0 {
                return 1
            }
            return 0
        case 1:
            if EventService.shared.featuredEvent.value != nil {
                return 1
            }
            return 0
        default:
            if filteredEventIds.isEmpty {
                return allEvents.count
            }
            return filteredEvents.count
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 30))
        view.backgroundColor = PannaUI.tableHeaderBackground
        let label = UILabel(frame: CGRect(x: 8, y: 0, width: tableView.frame.size.width - 16, height: 30))
        label.backgroundColor = .clear
        view.addSubview(label)
        label.font = UIFont.montserratMedium(size: 18)
        label.textColor = PannaUI.tableHeaderText
        view.clipsToBounds = true
        
        switch section {
        case 0:
            label.text = nil
        case 1:
            if EventService.shared.featuredEvent.value != nil {
                label.text = "Recommended"
            } else {
                label.text = nil
            }
        default:
            if EventService.shared.featuredEvent.value != nil {
                label.text = "All events"
            } else {
                label.text = nil
            }
        }
        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 0.1
        case 1:
            if EventService.shared.featuredEvent.value != nil {
                return 30
            } else {
                return 0.1
            }
        default:
            if EventService.shared.featuredEvent.value != nil {
                return 30
            } else {
                return 0.1
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch indexPath.section {
        case 0:
            if filteredEventIds.isEmpty && allEvents.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: "NoEventsCell", for: indexPath)
                if !firstLoaded {
                    cell.textLabel?.text = "Loading..."
                    return cell
                }
                
                if AuthService.isAnonymous {
                    if SettingsService.showPreview {
                        // showing preview
                        cell.textLabel?.text = "There are currently no games near you. Sign up to organize a game!"
                    } else {
                        cell.textLabel?.text = "There are currently no new games."
                    }
                } else if LocationService.shared.shouldFilterNearbyEvents {
                    cell.textLabel?.text = "There are currently no games near you."
                } else {
                    cell.textLabel?.text = "There are currently no new games."
                }
                return cell
            }
            return UITableViewCell()

        case 1:
            if let event = EventService.shared.featuredEvent.value {
                let cell : EventCell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventCell
                cell.delegate = self
                cell.setupWithEvent(event)
                LoggingService.shared.log(event: LoggingEvent.RecommendedEventCellViewed, info: nil)
                return cell
            }
            return UITableViewCell()
        default:
            let event: Balizinha.Event
            if filteredEventIds.isEmpty {
                guard indexPath.row < allEvents.count else { return UITableViewCell() }
                event = allEvents[indexPath.row]
            }
            else {
                guard indexPath.row < filteredEvents.count else { return UITableViewCell() }
                event = filteredEvents[indexPath.row]
            }
            let cell : EventCell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventCell
            cell.delegate = self
            cell.setupWithEvent(event)

            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0:
            if AuthService.isAnonymous {
                if SettingsService.showPreview {
                    // signup
                    didClickSignUp(nil)
                }
            } else {
                didClickAddEvent(sender: nil)
            }
            return
        case 1:
            if let event = EventService.shared.featuredEvent.value {
                performSegue(withIdentifier: "toEventDetails", sender: event)
            }
        default:
            let event: Balizinha.Event
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
}

extension MapViewController: TutorialDelegate {
    fileprivate var shouldShowTutorial: Bool {
        if AIRPLANE_MODE && TESTING {
            return false
        }
        if DefaultsManager.shared.value(forKey: DefaultsKey.showedTutorial.rawValue) as? Bool == true {
            return false
        }
        if DeepLinkService.shared.hasQueuedDeepLinkOnOpen {
            return false
        }
        if tutorialController != nil {
            return false
        }
        
        return true
    }
    static var count = 0
    func showTutorialIfNeeded() -> Bool {
        guard shouldShowTutorial else { return false }
        guard let controller = UIStoryboard(name: "Tutorial", bundle: nil).instantiateInitialViewController() as? TutorialViewController else { return false }
        tutorialController = controller
        
        present(controller, animated: true, completion: nil)
        
        controller.delegate = self
        LoggingService.shared.log(event: LoggingEvent.PreviewTutorialClicked, info: nil)

        DefaultsManager.shared.setValue(true, forKey: DefaultsKey.showedTutorial.rawValue)
        return true
    }
    
    func didTapTutorial() {
        // do nothing on tap
    }
    
    func didClickNext() {
        LoggingService.shared.log(event: LoggingEvent.PreviewTutorialClicked, info: nil)
        
        dismiss(animated: true, completion: nil)
        tutorialController = nil
        
        // only prompt for location after dismissing tutorial
        let _ = __once
    }
}

// MARK: - Preview
extension MapViewController {
    // EventCellDelegate
    override func previewEvent(_ event: Balizinha.Event) {
        print("Preview")
        performSegue(withIdentifier: "toEventDetails", sender: event)
        LoggingService.shared.log(event: LoggingEvent.PreviewEventClicked, info: nil)
    }
    
    // signup
    @objc func didClickSignUp(_ sender: Any?) {
        print("Create profile")
        SplashViewController.shared?.goToSignupLogin()
        LoggingService.shared.log(event: LoggingEvent.PreviewSignupClicked, info: nil)
    }
}
