//
//  RecurrenceToggleCell.swift
//  Panna
//
//  Created by Bobby Ren on 9/10/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import UIKit

protocol RecurrenceCellDelegate: class {
    func didSelectRecurrence(_ recurrence: Date.Recurrence)
}

class RecurrenceToggleCell: ToggleCell, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet private weak var containerRecurrence: UIView!
    @IBOutlet private weak var labelRecurrence: UILabel!
    @IBOutlet private weak var button: UIButton!

    private var recurrenceField: UITextField = UITextField()
    private var date: Date?
    private var datesForPicker: [Date] = [Date(), Date(), Date()]

    var recurrence: Date.Recurrence = .none
    weak var presenter: UIViewController?
    weak var recurrenceDelegate: RecurrenceCellDelegate?

    private var datePickerView: UIPickerView = UIPickerView()
    private var keyboardDoneButtonView: UIToolbar = UIToolbar()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupInputs()
    }

    private func setupInputs() {
        // textfield keyboard
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.default
        keyboardDoneButtonView.tintColor = UIColor.red
        let save: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(done))
        let flex: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        keyboardDoneButtonView.setItems([flex, save], animated: true)

        recurrenceField.inputView = datePickerView
        recurrenceField.inputAccessoryView = keyboardDoneButtonView
        if recurrenceField.superview == nil {
            self.addSubview(recurrenceField)
        }

        datePickerView.sizeToFit()
        datePickerView.backgroundColor = .white
        datePickerView.delegate = self
        datePickerView.dataSource = self
        self.generatePickerDates()
    }
    
    func generatePickerDates() {
        /*
        guard self.datesForPicker.count == 0 else { return }
        
        for row in 0..<FUTURE_DAYS {
            let date = Date().addingTimeInterval(3600*24*TimeInterval(row))
            datesForPicker.append(date)
        }
        */
    }
    
    override func didToggleSwitch(_ sender: UISwitch?) {
        if switchToggle.isOn {
            promptForRecurrence()
        } else {
            selectRecurrence(.none)
        }
    }
    override func refresh() {
        switchToggle.isOn = recurrence != .none
        labelRecurrence.text = recurrenceDateLabelText(recurrence, date)
        containerRecurrence.isHidden = !switchToggle.isOn
    }
    
    internal func recurrenceDateLabelText(_ recurrence: Date.Recurrence, _ date: Date?) -> String {
        var string = recurrence.rawValue.capitalized
        if let date = date {
            let dateString = date.dateString()
            string = string + " until " + dateString
        }
        return string
    }
    
    @IBAction func didClickButton(_ sender: Any?) {
        promptForDate()
    }
    
    func promptForRecurrence() {
        let alert = UIAlertController(title: "Select recurrence", message: nil, preferredStyle: .actionSheet)
        for option in [Date.Recurrence.daily, Date.Recurrence.weekly, Date.Recurrence.monthly] {
            alert.addAction(UIAlertAction(title: option.rawValue.capitalized, style: .default, handler: { (action) in
                self.selectRecurrence(option)
            }))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            self.selectRecurrence(.none)
        })
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad)
        {
            alert.popoverPresentationController?.sourceView = self
            alert.popoverPresentationController?.sourceRect = containerRecurrence.frame
        }
        presenter?.present(alert, animated: true, completion: nil)
    }
    
    func selectRecurrence(_ recurrence: Date.Recurrence) {
        self.recurrence = recurrence
        refresh()
        
        recurrenceDelegate?.didSelectRecurrence(recurrence)
        // select date
        if recurrence != .none {
            promptForDate()
        }
    }
    
    func promptForDate() {
        recurrenceField.becomeFirstResponder()
    }
    
    @objc func done() {
        // on button click on toolbar for day, time pickers
        recurrenceField.resignFirstResponder()
        datePickerValueChanged(datePickerView)
        refresh()
    }

    func datePickerValueChanged(_ sender:UIPickerView) {
        let row = sender.selectedRow(inComponent: 0)
        guard row < self.datesForPicker.count else { return }
        self.date = self.datesForPicker[row]
    }

    // MARK: - UIPickerViewDataSource, UIPickerViewDelegate
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 10 // how many total recurrence dates?
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row < self.datesForPicker.count {
            return self.datesForPicker[row].dateStringForPicker()
        }
        return ""
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // let user pick more dates and click done
        print("Didselectrow")
    }
}
