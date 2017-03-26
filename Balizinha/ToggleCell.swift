//
//  ToggleCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/26/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

protocol ToggleCellDelegate: class {
    func didToggleSwitch(isOn: Bool)
}
class ToggleCell: UITableViewCell {
    
    @IBOutlet var labelText: UILabel!
    @IBOutlet var switchToggle: UISwitch!

    weak var delegate: ToggleCellDelegate?
    
    @IBAction func didToggleSwitch(sender: UISwitch?) {
        if let toggle = sender {
            self.delegate?.didToggleSwitch(isOn: toggle.isOn)
        }
    }
}
