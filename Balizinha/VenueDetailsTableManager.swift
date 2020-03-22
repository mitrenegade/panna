//
//  VenueDetailsTableManager.swift
//  Panna
//
//  Created by Bobby Ren on 3/6/20.
//  Copyright © 2020 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

protocol VenueDetailsTableManagerDelegate {
    func selectPhoto()
}

class VenueDetailsTableManager: NSObject, UITableViewDataSource, UITableViewDelegate {

    var inputName: UITextField?
    var inputType: UITextField?
    var typePickerView: UIPickerView = UIPickerView()

    private enum Row: Int, CaseIterable {
        case photo = 0
        case name = 1
        case type = 2
    }
    
    var venue: Venue?
    var delegate: VenueDetailsTableManagerDelegate?
    var currentType: Venue.SpaceType?

    init(venue: Venue?) {
        self.venue = venue
        
        super.init()
        
        typePickerView.sizeToFit()
        typePickerView.delegate = self
        typePickerView.dataSource = self
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
                inputName?.delegate = self
                return cell
            case .type:
                let cell = tableView.dequeueReusableCell(withIdentifier: "typeCell", for: indexPath) as! DetailCell
                cell.labelAttribute.text = "Type"
                cell.valueTextField.text = venue?.type.rawValue
                cell.valueTextField.placeholder = "Select venue type"
                inputType = cell.valueTextField
                inputType?.inputView = typePickerView
                inputType?.delegate = self
                return cell
            }
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch Row(rawValue: indexPath.row) {
        case .photo:
            delegate?.selectPhoto()
            break
        case .name:
            break
        case .type:
            typePickerView.reloadAllComponents()
            
            break
        default:
            break
        }
    }
}

extension VenueDetailsTableManager: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
}

extension VenueDetailsTableManager: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        //print("Reloaded number of rows")
        return Venue.SpaceType.allCases.count // datePickerView: default 3 months
    }

    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        //print("Reloaded components")
        let types = Venue.SpaceType.allCases
        if types[row] == .unknown {
            return "Select event type"
        }
        return "\(types[row].rawValue)"
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // let user pick more dates and click done
        guard pickerView != self.typePickerView else { return }
        let types = Venue.SpaceType.allCases
        currentType = types[row]
    }
}
