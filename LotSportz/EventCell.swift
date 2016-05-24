//
//  EventCell.swift
//  LotSportz
//
//  Created by Tom Strissel on 5/18/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class EventCell: UITableViewCell {

    @IBOutlet var btnAction: UIButton!
    @IBOutlet var labelFull: UILabel!
    @IBOutlet var labelAttendance: UILabel!
    @IBOutlet var labelLocation: UILabel!
    @IBOutlet var labelTime: UILabel!
    @IBOutlet var labelDate: UILabel!
    @IBOutlet var eventLogo: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.eventLogo.layer.cornerRadius = self.eventLogo.frame.size.height / 2
        self.eventLogo.layer.borderWidth = 1.0
        self.eventLogo.layer.masksToBounds = true
        
        self.btnAction.layer.cornerRadius = self.btnAction.frame.size.height / 5
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func didTapCancel(sender: AnyObject) {
        print("Tapped Cancel/Join")
    }
}
