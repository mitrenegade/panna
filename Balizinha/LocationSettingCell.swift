//
//  LocationSettingCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 12/12/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

class LocationSettingCell: ToggleCell {
    @IBOutlet weak var labelInfo: UILabel!
    
    override func configure() {
        let filterEvents = LocationService.shared.shouldFilterNearbyEvents
        switchToggle.isOn = filterEvents
        
        super.configure()
    }
    
    override func refresh() {
        super.refresh()
        if switchToggle.isOn {
            labelInfo.text = "You will only see games near you"
        } else {
            labelInfo.text = "You will see all games"
        }
    }
}
