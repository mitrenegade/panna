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

class VenueDetailsTableManager: NSObject {

    var inputName: UITextField?
    var inputType: UITextField?
    private let typePickerView: UIPickerView = UIPickerView()
    private let keyboardDoneButtonView = UIToolbar()
    weak var tableView: UITableView?

    private enum Row: Int, CaseIterable {
        case photo = 0
        case name = 1
        case type = 2
    }
    
    var venue: Venue?
    var delegate: VenueDetailsTableManagerDelegate?
    var currentType: Venue.SpaceType?

    init(venue: Venue?, tableView: UITableView?) {
        self.venue = venue
        self.tableView = tableView

        super.init()
        tableView?.dataSource = self
        tableView?.delegate = self
        setupPicker()
        
        currentType = venue?.type
    }
    
    func setupPicker() {
        typePickerView.sizeToFit()
        typePickerView.delegate = self
        typePickerView.dataSource = self

        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.default
        keyboardDoneButtonView.tintColor = UIColor.white
        let save: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneSelectingType))
        let cancel: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(cancelSelectingType))

        let flex: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        keyboardDoneButtonView.setItems([cancel, flex, save], animated: true)
    }
    
    @objc func doneSelectingType() {
        tableView?.endEditing(true)
        tableView?.reloadData()
    }

    @objc func cancelSelectingType() {
        currentType = venue?.type
        doneSelectingType()
    }
}

extension VenueDetailsTableManager: UITableViewDataSource, UITableViewDelegate {
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
                cell.valueTextField.text = currentType?.rawValue.capitalized
                cell.valueTextField.placeholder = "Select venue type"
                inputType = cell.valueTextField
                inputType?.inputView = typePickerView
                inputType?.inputAccessoryView = keyboardDoneButtonView
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
        case .name, .type:
            break
        default:
            break
        }
    }
}

extension VenueDetailsTableManager: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == inputType {
            typePickerView.reloadAllComponents()
            if let type = currentType, let index = Venue.SpaceType.allCases.firstIndex(of: type) {
                typePickerView.selectRow(index, inComponent: 0, animated: true)
            }
        }
    }
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
            return "Select Venue type"
        }
        let type: String = types[row].rawValue
        return "\(type.capitalized)"
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // let user pick more dates and click done
        guard pickerView == self.typePickerView else { return }
        let types = Venue.SpaceType.allCases
        currentType = types[row]
        tableView?.reloadData()
    }
}
