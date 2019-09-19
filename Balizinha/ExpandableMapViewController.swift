//
//  ExpandableMapViewController.swift
//  
//
//  Created by Bobby Ren on 3/5/17.
//
//

import UIKit
import MapKit
import Balizinha

class ExpandableMapViewController: UIViewController {

    @IBOutlet weak var labelLocation: UILabel!
    @IBOutlet weak var buttonExpand: UIButton!
    @IBOutlet weak var buttonDirections: UIButton?
    @IBOutlet weak var mapView: MKMapView!
    
    private let HEIGHT_MAP: CGFloat = 300
    private let HEIGHT_NO_MAP: CGFloat = 100
    private let HEIGHT_NO_LOCATION: CGFloat = 60

    fileprivate var shouldShowMap: Bool = true {
        didSet {
            toggleMap(show: shouldShowMap)
        }
    }
    
    var event: Balizinha.Event?
    weak var delegate: SectionComponentDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let text: String
        if let place = event?.place, let locationString = event?.locationString {
            text = "\(place)\n\(locationString)"
        }
        else if let place = event?.place {
            text = "\(place)"
        }
        else {
            text = event?.locationString ?? "Location TBA"
        }
        
        let string = NSMutableAttributedString(string:text, attributes:[NSAttributedString.Key.font: UIFont.montserratMedium(size: 15)])
        if let locationString = event?.locationString {
            let range = (text as NSString).range(of: locationString)
            string.addAttributes([NSAttributedString.Key.font : UIFont.montserrat(size: 14)], range: range)
        }
        labelLocation.attributedText = string
        
        if let event = event, let lat = event.lat, let lon = event.lon {
            let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lon), span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
            mapView.setRegion(region, animated: false)
            
            let annotation = MKPointAnnotation()
            let coordinate = CLLocationCoordinate2DMake(lat, lon)
            annotation.coordinate = coordinate
            annotation.title = event.name
            annotation.subtitle = event.locationString
            mapView.addAnnotation(annotation)
        }
        
        // show map based on default
        shouldShowMap = true
        if case .denied = LocationService.shared.locationState.value {
            shouldShowMap = false
            buttonExpand.isHidden = true
            mapView.isHidden = true
            delegate?.componentHeightChanged(controller: self, newHeight: HEIGHT_NO_LOCATION)
        }
    }

    @IBAction func didClickButtonExpand(_ sender: Any?) {
        shouldShowMap = !shouldShowMap
        
        LoggingService.shared.log(event: .ShowOrHideMap, info: ["show": shouldShowMap])
    }
    
    @IBAction func didClickButtonDirections(_ sender: Any?) {
        MapService.goToMapDirections(event)
    }
    
    fileprivate func toggleMap(show: Bool) {
        if show {
            mapView.isHidden = false
            delegate?.componentHeightChanged(controller: self, newHeight: HEIGHT_MAP)
            buttonExpand.setTitle("Hide map", for: .normal)
        }
        else {
            mapView.isHidden = true
            delegate?.componentHeightChanged(controller: self, newHeight: HEIGHT_NO_MAP)
            buttonExpand.setTitle("Show map", for: .normal)
        }
    }
}

extension ExpandableMapViewController: MKMapViewDelegate {
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
        view.calloutOffset = CGPoint(x: -20, y: -20)
        return view
    }
}

