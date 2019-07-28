//
//  LeagueInquiryViewController.swift
//  Panna
//
//  Created by Bobby Ren on 9/19/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class LeagueInquiryViewController: FeedbackViewController {

    var pickerView: UIPickerView = UIPickerView()
    enum Subject: String, CaseIterable {
        case createLeague = "I want to create a league"
        case joinLeague = "I want to join a private league"
        case organize = "I want to become an organizer"
        case other = "Other"
    }

    override var isLeagueInquiry: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "About Leagues"

        pickerView.sizeToFit()
        pickerView.backgroundColor = .white
        pickerView.delegate = self
        pickerView.dataSource = self
        inputSubject.inputView = pickerView
        inputSubject.placeholder = "Select a topic"
        
        let keyboardNextButtonView = UIToolbar()
        keyboardNextButtonView.sizeToFit()
        keyboardNextButtonView.barStyle = UIBarStyle.black
        keyboardNextButtonView.isTranslucent = true
        keyboardNextButtonView.tintColor = UIColor.white
        let cancel: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(cancelInput))
        let flex: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let next: UIBarButtonItem = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(nextInput))
        keyboardNextButtonView.setItems([flex, cancel, next], animated: true)
        
        inputSubject.inputAccessoryView = keyboardNextButtonView
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(close))
    }
    
    @objc override func close() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func nextInput() {
        inputSubject.resignFirstResponder()
        if let email = inputEmail.text, email.isValidEmail() {
            inputDetails.becomeFirstResponder()
        } else {
            inputEmail.becomeFirstResponder()
        }
    }
}

extension LeagueInquiryViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    //MARK: - Delegates and data sources
    //MARK: Data Sources
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Subject.allCases.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Subject.allCases[row].rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard row > 0 else { return }
        guard row < Subject.allCases.count else { return }

        inputSubject.text = Subject.allCases[row].rawValue
    }
    
    func datePickerValueChanged(_ sender:UIPickerView) {
        let row = sender.selectedRow(inComponent: 0)
        pickerView(pickerView, didSelectRow: row, inComponent: 0)
    }
}
