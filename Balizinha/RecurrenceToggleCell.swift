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
    func promptForDate(completion: @escaping ((Date?) -> Void))
}
class RecurrenceToggleCell: ToggleCell {
    @IBOutlet weak var containerRecurrence: UIView!
    @IBOutlet weak var labelRecurrence: UILabel!
    @IBOutlet weak var button: UIButton!
    weak var presenter: UIViewController?
    var recurrence: Date.Recurrence = .none
    var date: Date?
    weak var recurrenceDelegate: RecurrenceCellDelegate?
    
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
        recurrenceDelegate?.promptForDate(completion: { [weak self] (date) in
            self?.date = date
            self?.refresh()
        })
    }
}
