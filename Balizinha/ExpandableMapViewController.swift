//
//  ExpandableMapViewController.swift
//  
//
//  Created by Bobby Ren on 3/5/17.
//
//

import UIKit
import MapKit

class ExpandableMapViewController: UIViewController {

    @IBOutlet var labelLocation: UILabel!
    @IBOutlet var buttonExpand: UIButton!
    @IBOutlet var mapView: MKMapView!
    
    var event: Event?
    weak var delegate: EventDisplayComponentDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.buttonExpand.isEnabled = false
    
        let text: String
        if let place = event?.place, let locationString = event?.locationString {
            text = "\(place), \(locationString)"
        }
        else if let place = event?.place {
            text = "\(place)"
        }
        else {
            text = event?.locationString ?? "Location TBA"
        }
        self.labelLocation.text = text
    }

    @IBAction func didClickButtonExpand(_ sender: Any?) {
        print("none")
    }
    
    func toggleMap(show: Bool) {
        if show {
            self.delegate?.componentHeightChanged(controller: self, newHeight: 80)
        }
        else {
            self.delegate?.componentHeightChanged(controller: self, newHeight: 35)
        }
    }
}
