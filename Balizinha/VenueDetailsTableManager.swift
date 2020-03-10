//
//  VenueDetailsTableManager.swift
//  Panna
//
//  Created by Bobby Ren on 3/6/20.
//  Copyright © 2020 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class VenueDetailsTableManager: NSObject, UITableViewDataSource, UITableViewDelegate {

    var inputName: UITextField?

    private enum Row: Int, CaseIterable {
        case photo = 0
        case name = 1
        case type = 2
    }
    
    var venue: Venue?

    init(venue: Venue?) {
        self.venue = venue
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Row.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let row = Row(rawValue: indexPath.row) {
            switch row {
            case .photo:
                let cell = tableView.dequeueReusableCell(withIdentifier: "photoCell", for: indexPath) as! PhotoCell
                cell.url = venue?.photoUrl
                return cell
            case .name:
                let cell = tableView.dequeueReusableCell(withIdentifier: "nameCell", for: indexPath) as! DetailCell
                cell.labelAttribute.text = "Name"
                cell.valueTextField.text = venue?.name
                cell.valueTextField.placeholder = "e.g. Fenway"
                inputName = cell.valueTextField
                return cell
            case .type:
                let cell = tableView.dequeueReusableCell(withIdentifier: "typeCell", for: indexPath) as! DetailCell
                cell.labelAttribute.text = "Type"
                cell.valueTextField.text = venue?.type.rawValue
                cell.valueTextField.placeholder = "Select venue type"
                return cell
            }
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
