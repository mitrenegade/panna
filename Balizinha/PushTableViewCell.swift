//
//  PushTableViewCell.swift
// Balizinha
//
//  Created by Tom Strissel on 5/19/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class PushTableViewCell: ToggleCell {

    override func configure() {
        if #available(iOS 10.0, *), NotificationService.shared.userReceivesNotifications() {
            self.switchToggle.setOn(true, animated: true)
        } else {
            self.switchToggle.setOn(false, animated: true)
        }
    }
    
    @IBAction override func didToggleSwitch(_ sender: UISwitch?) {
        super.didToggleSwitch(sender)
        
        let isOn = switchToggle.isOn
        print("Switch changed to \(isOn)")
        if #available(iOS 10.0, *) {
            NotificationService.shared.toggleUserReceivesNotifications(isOn)
        }
    }
}
