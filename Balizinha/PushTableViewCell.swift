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
        switchToggle.setOn(userReceivesNotifications, animated: true)

        let pushEnabled = !NotificationService.shared.pushRequestFailed
        switchToggle.isEnabled = pushEnabled
    }
}
