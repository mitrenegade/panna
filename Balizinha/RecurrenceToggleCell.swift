//
//  RecurrenceToggleCell.swift
//  Panna
//
//  Created by Bobby Ren on 9/10/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import UIKit

protocol RecurrenceCellDelegate: class {
    func didSelectRecurrence(_ recurrence: Date.Recurrence, _ recurrenceEndDate: Date?)
}

class RecurrenceToggleCell: ToggleCell, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet private weak var containerRecurrence: UIView!
    @IBOutlet private weak var labelRecurrence: UILabel!
    @IBOutlet private weak var button: UIButton!

    private var recurrenceField: UITextField = UITextField()
    private (set) var datesForPicker: [Date] = []

    var recurrence: Date.Recurrence = .none
    var recurrenceStartDate: Date? {
        didSet {
            refreshToggleEnabled()
        }
    }
    var recurrenceEndDate: Date?
    weak var presenter: UIViewController?
    weak var recurrenceDelegate: RecurrenceCellDelegate?

    private var datePickerView: UIPickerView = UIPickerView()
    private var keyboardDoneButtonView: UIToolbar = UIToolbar()
    
    private var viewModel: RecurrenceToggleCellViewModel = RecurrenceToggleCellViewModel()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupInputs()
        refreshToggleEnabled()
    }

    private func setupInputs() {
        // textfield keyboard
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.default
        keyboardDoneButtonView.tintColor = UIColor.red
        let save: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(done))
        let cancel: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(cancelRecurrence))
        let flex: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        save.tintColor = UIColor(red: 62.0/255.0, green: 82.0/255.0, blue: 101.0/255.0, alpha: 1)
        cancel.tintColor = UIColor(red: 62.0/255.0, green: 82.0/255.0, blue: 101.0/255.0, alpha: 1)

        keyboardDoneButtonView.setItems([cancel, flex, save], animated: true)

        recurrenceField.inputView = datePickerView
        recurrenceField.inputAccessoryView = keyboardDoneButtonView
        if recurrenceField.superview == nil {
            self.addSubview(recurrenceField)
        }

        datePickerView.sizeToFit()
        datePickerView.backgroundColor = .white
        datePickerView.delegate = self
        datePickerView.dataSource = self
    }
    
    func refreshToggleEnabled() {
        // switch should only be enabled if a start date exists
        let enabled: Bool = recurrenceStartDate != nil
        switchToggle.isEnabled = enabled
        labelRecurrence.alpha = enabled ? 1 : 0
    }
    
    func generatePickerDates() {
        guard let startDate = recurrenceStartDate else { return }
        let endDate = startDate.addingTimeInterval(24*3600*7*52)
        self.datesForPicker = viewModel.datesForRecurrence(recurrence, startDate: startDate, endDate: endDate)
    }
    
    override func didToggleSwitch(_ sender: UISwitch?) {
        if switchToggle.isOn {
            promptForRecurrence()
        } else {
            cancelRecurrence()
        }
    }
    override func refresh() {
        switchToggle.isOn = recurrence != .none
        labelRecurrence.text = recurrenceDateLabelText(recurrence, recurrenceEndDate)
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
            self.cancelRecurrence()
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
        
        // select date
        recurrenceDelegate?.didSelectRecurrence(recurrence, nil)
        if recurrence != .none {
            promptForDate()
        }
    }
    
    func promptForDate() {
        generatePickerDates()
        recurrenceField.becomeFirstResponder()
    }
    
    @objc func done() {
        // on button click on toolbar for day, time pickers
        recurrenceField.resignFirstResponder()
        let row = datePickerView.selectedRow(inComponent: 0)
        guard row < self.datesForPicker.count else { return }
        recurrenceEndDate = self.datesForPicker[row]
        recurrenceDelegate?.didSelectRecurrence(recurrence, recurrenceEndDate)
        refresh()
    }
    
    @objc func cancelRecurrence() {
        selectRecurrence(.none)
        recurrenceField.resignFirstResponder()
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
