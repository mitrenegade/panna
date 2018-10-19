//
//  PushTableViewCell.swift
// Balizinha
//
//  Created by Tom Strissel on 5/19/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class PushTableViewCell: ToggleCell {

    override func configure() {
        let userReceivesNotifications = PlayerService.shared.current.value?.notificationsEnabled ?? false
        let pushEnabled = !NotificationService.shared.pushRequestFailed
        self.switchToggle.setOn(userReceivesNotifications && pushEnabled, animated: true)
    }
}
