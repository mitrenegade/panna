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

class MapViewController: UIViewController {
    // Data
    
    // MARK: MapView
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: TableView
    @IBOutlet weak var tableView: UITableView!
    var snapshot: [FIRDataSnapshot]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let eventQueryRef = firRef.child("events")
        
        // sort by time
        eventQueryRef.queryOrdered(byChild: "startTime")
        
        // filter for type
        //if let _ = type {
        //    eventQueryRef.queryEqual(toValue: type!, childKey: "type")
        //}
        
        // TODO: filter by owner
        
        // do query
        var handle: UInt = 0
        handle = eventQueryRef.observe(.value) { (snapshot: FIRDataSnapshot!) in
            // this block is called for every result returned
            self.snapshot = snapshot.children.allObjects as? [FIRDataSnapshot]
            self.tableView.reloadData()
        }
    }

}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("region changed")
        
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("user location changed")
    }
}

extension MapViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.snapshot?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : EventCell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventCell
        //cell.delegate = self

        guard let eventDict = snapshot?[indexPath.row] else {
            return cell
        }
        let event = Event(snapshot: eventDict)
        cell.setupWithEvent(event)
        
        return cell
    }
}
