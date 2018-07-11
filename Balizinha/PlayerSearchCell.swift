//
//  PlayerSearchCell.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 5/12/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit

protocol PlayerSearchDelegate: class {
    func search(for string: String?)
}

class PlayerSearchCell: UITableViewCell {
    
    @IBOutlet weak var inputSearch: UITextField!
    @IBOutlet weak var buttonSearch: UIButton!
    
    weak var delegate: PlayerSearchDelegate?

    @IBAction func didClickSearch(_ sender: Any?) {
        delegate?.search(for: inputSearch.text)
    }
}

extension PlayerSearchCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        didClickSearch(nil)
        return true
    }
}
