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

    @IBOutlet weak var labelLocation: UILabel!
    @IBOutlet weak var buttonExpand: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var constraintLabel: NSLayoutConstraint!
    @IBOutlet weak var constraintMapHeight: NSLayoutConstraint!
    
    var shouldShowMap: Bool = false {
        didSet {
            toggleMap(show: shouldShowMap)
        }
    }
    
    var event: Event?
    weak var delegate: SectionComponentDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        buttonExpand.isEnabled = false
    
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
    }

    @IBAction func didClickButtonExpand(_ sender: Any?) {
        shouldShowMap = !shouldShowMap
    }
    
    fileprivate func toggleMap(show: Bool) {
        if show {
            constraintMapHeight.constant = 200
            self.delegate?.componentHeightChanged(controller: self, newHeight: buttonExpand.frame.size.height + constraintMapHeight.constant)
        }
        else {
            constraintMapHeight.constant = 0
            self.delegate?.componentHeightChanged(controller: self, newHeight: buttonExpand.frame.size.height)
        }
    }
}
