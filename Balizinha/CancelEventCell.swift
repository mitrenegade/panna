//
//  CancelEventCell.swift
//  Panna
//
//  Created by Bobby Ren on 4/11/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class CancelEventCell: UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
    var viewModel: CancelEventViewModel?

    func configure(_ event: Balizinha.Event) {
        viewModel = CancelEventViewModel(event: event)
        label.text = viewModel?.cancelCellText
    }
}
