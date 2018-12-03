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
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var constraintLabel: NSLayoutConstraint!
    @IBOutlet weak var constraintMapHeight: NSLayoutConstraint!
    
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
        
        let string = NSMutableAttributedString(string:text, attributes:[NSAttributedStringKey.font: UIFont.montserratMedium(size: 15)])
        if let locationString = event?.locationString {
            let range = (text as NSString).range(of: locationString)
            string.addAttributes([NSAttributedStringKey.font : UIFont.montserrat(size: 14)], range: range)
        }
        labelLocation.attributedText = string
        
        if let event = event, let lat = event.lat, let lon = event.lon {
            let region = MKCoordinateRegionMake(CLLocationCoordinate2D(latitude: lat, longitude: lon), MKCoordinateSpanMake(0.005, 0.005))
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
    }

    @IBAction func didClickButtonExpand(_ sender: Any?) {
        shouldShowMap = !shouldShowMap
        
        LoggingService.shared.log(event: .ShowOrHideMap, info: ["show": shouldShowMap])
    }
    
    fileprivate func toggleMap(show: Bool) {
        if show {
            constraintMapHeight.constant = 200
            delegate?.componentHeightChanged(controller: self, newHeight: mapView.frame.origin.y + constraintMapHeight.constant)
            buttonExpand.setTitle("Hide map", for: .normal)
        }
        else {
            constraintMapHeight.constant = 0
            delegate?.componentHeightChanged(controller: self, newHeight: mapView.frame.origin.y + constraintMapHeight.constant)
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
