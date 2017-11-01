//
//  PlaceResultsViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 11/1/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import MapKit

class PlaceResultsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var matchingItems:[MKMapItem] = []
    //var mapView: MKMapView? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}

extension PlaceResultsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        //        guard let mapView = mapView,
        
        guard let searchBarText = searchController.searchBar.text else { return }
        
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBarText
        //        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else {
                return
            }
            self.matchingItems = response.mapItems
            self.tableView.reloadData()
        }
    }
}

extension PlaceResultsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceCell")!
        let selectedItem = matchingItems[indexPath.row].placemark
        cell.textLabel?.text = selectedItem.name
        cell.detailTextLabel?.text = ""
        return cell
    }
}

