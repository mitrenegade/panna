//
//  VenuesListViewController.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 5/16/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import Firebase
import Balizinha
import RenderCloud

class VenuesListViewController: SearchableListViewController {
    var reference: Reference?
    var venues: [Venue] = []

    override var refName: String {
        return "venues"
    }
    
    override var sections: [Section] {
        return [("Venues", venues)]
    }
    
    override func createObject(from snapshot: Snapshot) -> FirebaseBaseModel? {
        return Venue(snapshot: snapshot)
    }

    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        navigationItem.title = "Venues"
        if AIRPLANE_MODE {
            reference = MockDatabaseReference(snapshot: MockDataSnapshot(exists: true, value: ["name": "abc"]))
        } else {
            reference = firRef
        }

        super.viewDidLoad()
        
        activityOverlay.show()
        load() { [weak self] in
            self?.search(for: nil)
            self?.activityOverlay.hide()
        }

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(createVenue))
    }
    
    @objc func createVenue() {
        performSegue(withIdentifier: "toLocationSearch", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toLocationSearch", let controller = segue.destination as? PlaceSearchViewController {
            controller.delegate = self
            if let venue = sender as? Venue {
                controller.currentVenue = venue
            }
        }
    }
}

// MARK: - TableView Datasource and Delegate
extension VenuesListViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "VenueCell", for: indexPath) as? VenueCell else { return UITableViewCell() }
        if indexPath.row < venues.count {
            let venue = venues[indexPath.row]
            cell.configure(with: venue)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath.row < venues.count else { return }
        let venue = venues[indexPath.row]
        
        // TODO: if creating/editing event, set event's venue
        // if viewing/editing venue, go to venue creation page
        //performSegue(withIdentifier: "toLocationSearch", sender: venue)
    }
}

// search and filtering
extension VenuesListViewController {
    @objc override func updateSections(_ newObjects: [FirebaseBaseModel]) {
        venues = newObjects.compactMap { $0 as? Venue }
        // TODO: filter by distance
        venues.sort(by: { (p1, p2) -> Bool in
            guard let t1 = p1.createdAt else { return false }
            guard let t2 = p2.createdAt else { return true}
            return t1 > t2
        })
    }
    
    override func doFilter(_ currentSearch: String) -> [FirebaseBaseModel] {
        return objects.filter {(_ object: FirebaseBaseModel) in
            guard currentSearch.count > 2 else { return false } // only match 3 characters or more
            guard let venue = object as? Venue else { return false }
            let nameMatch = venue.name?.lowercased().contains(currentSearch) ?? false
            let idMatch = venue.id.lowercased().contains(currentSearch)
            let streetMatch = venue.street?.lowercased().contains(currentSearch) ?? false
            let cityStateMatch = venue.shortString?.lowercased().contains(currentSearch) ?? false
            return nameMatch || idMatch || streetMatch || cityStateMatch
        }
    }
}

// MARK: PlaceSearchDelegate
extension VenuesListViewController: PlaceSelectDelegate {
    func didSelect(venue: Venue?) {
        activityOverlay.show()
        load() { [weak self] in
            self?.search(for: nil)
            self?.activityOverlay.hide()
        }
        navigationController?.popToViewController(self, animated: true)
    }
}
