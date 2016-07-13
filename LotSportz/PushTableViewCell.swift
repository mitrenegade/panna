//
//  PushTableViewCell.swift
//  LotSportz
//
//  Created by Tom Strissel on 5/19/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class PushTableViewCell: UITableViewCell {

    @IBOutlet var pushSwitch: UISwitch!
    @IBOutlet var labelPush: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func refresh() {
        if NotificationService.userReceivesNotifications() {
            self.pushSwitch.setOn(true, animated: true)
        } else {
            self.pushSwitch.setOn(false, animated: true)
        }
    }

    @IBAction func switchState(sender: AnyObject) {
        print("Switch changed to \(self.pushSwitch.on)")
        NotificationService.toggleUserReceivesNotifications(self.pushSwitch.on)
    }
}
