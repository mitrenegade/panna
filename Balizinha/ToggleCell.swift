//
//  ToggleCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/26/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

protocol ToggleCellDelegate: class {
    func didToggle(_ toggle: UISwitch, isOn: Bool)
}
class ToggleCell: UITableViewCell {
    
    @IBOutlet var labelText: UILabel!
    @IBOutlet var switchToggle: UISwitch!
    @IBOutlet weak var input: UITextField?

    weak var delegate: ToggleCellDelegate?
    
    @IBAction func didToggleSwitch(_ sender: UISwitch?) {
        if let toggle = sender {
            self.delegate?.didToggle(toggle, isOn: toggle.isOn)
        }
        refresh()
    }
    
    func configure() {
        refresh()
    }
    
    func refresh() {
        
    }
}
