//
//  LocationSettingCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 12/12/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

class LocationSettingCell: ToggleCell {

    override func configure() {
        let filterEvents = LocationService.shared.shouldFilterNearbyEvents
        switchToggle.isOn = filterEvents
    }
}
