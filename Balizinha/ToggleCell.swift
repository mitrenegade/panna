//
//  ToggleCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/26/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

protocol ToggleCellDelegate: class {
    func didToggle(switch: UISwitch, isOn: Bool)
}
class ToggleCell: UITableViewCell {
    
    @IBOutlet var labelText: UILabel!
    @IBOutlet var switchToggle: UISwitch!
    @IBOutlet weak var input: UITextField?

    weak var delegate: ToggleCellDelegate?
    
    @IBAction func didToggleSwitch(_ sender: UISwitch?) {
        if let toggle = sender {
            self.delegate?.didToggle(switch: toggle, isOn: toggle.isOn)
        }
    }
    
    func configure() {
        
    }
}
