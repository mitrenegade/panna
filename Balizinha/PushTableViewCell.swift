//
//  PushTableViewCell.swift
// Balizinha
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

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func refresh() {
        if #available(iOS 10.0, *), NotificationService.userReceivesNotifications() {
            self.pushSwitch.setOn(true, animated: true)
        } else {
            self.pushSwitch.setOn(false, animated: true)
        }
    }

    @IBAction func switchState(_ sender: AnyObject) {
        print("Switch changed to \(self.pushSwitch.isOn)")
        if #available(iOS 10.0, *) {
            NotificationService.toggleUserReceivesNotifications(self.pushSwitch.isOn)
        }
    }
}
