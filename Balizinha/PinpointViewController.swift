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
    
    var currentLocation: CLLocationCoordinate2D? {
        didSet {
            if let location = currentLocation {
                var span = MKCoordinateSpanMake(0.05, 0.05)
                if mapView.region.span.latitudeDelta < 0.05 || mapView.region.span.longitudeDelta < 0.05 {
                    span = mapView.region.span
                }
                let region = MKCoordinateRegionMake(location, span)
                mapView.setRegion(region, animated: true)
            }
        }
    }
    @IBOutlet weak var pinView: UIView!
    
    var currentEvent: Balizinha.Event?
    fileprivate var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        LocationService.shared.startLocation(from: self)
        if let event = currentEvent, let lat = event.lat, let lon = event.lon {
            let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            currentLocation = location
        } else {
            LocationService.shared.observedLocation.asObservable().subscribe(onNext: { [weak self] (state) in
                switch state {
                case .located(let location):
                    self?.currentLocation = location.coordinate
                    self?.disposeBag = DisposeBag()
                default:
                    print("still locating")
                }
            }).disposed(by: disposeBag)
        }
    }
}
extension PinpointViewController: MKMapViewDelegate {
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let location = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        if annotation is MKUserLocation {
//            //return nil so map view draws "blue dot" for standard user location
//            return nil
//        }
//
//        let button = UIButton(type: .custom)
//        button.setTitle("Go", for: .normal)
//        button.setTitleColor(.white, for: .normal)
//        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
//        button.layer.cornerRadius = button.frame.size.width / 2
//        button.backgroundColor = UIColor.blue
//        button.addTarget(self, action: #selector(PlaceSearchViewController.selectLocation), for: .touchUpInside)
//
//        let reuseId = "pin"
//        if #available(iOS 11.0, *) {
//            // 3
//            let identifier = "marker"
//            var view: MKMarkerAnnotationView
//            // 4
//            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
//                as? MKMarkerAnnotationView {
//                dequeuedView.annotation = annotation
//                view = dequeuedView
//            } else {
//                // 5
//                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
//                view.canShowCallout = true
//                view.calloutOffset = CGPoint(x: -5, y: 5)
//                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
//            }
//            view.leftCalloutAccessoryView = button
//            return view
//        } else {
//            // Fallback on earlier versions
//            let pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView ??  MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
//            pinView.pinTintColor = UIColor.orange
//            pinView.canShowCallout = true
//            pinView.leftCalloutAccessoryView = button
//            return pinView
//        }
        return nil
    }
}
