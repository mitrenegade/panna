//
//  MapViewModel.swift
//  Panna
//
//  Created by Bobby Ren on 10/14/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import UIKit

class MapViewModel: NSObject {
    let settingsService: SettingsService
    let locationService: LocationService
    
    init(settingsService: SettingsService = SettingsService.shared, locationService: LocationService = LocationService.shared) {
        self.settingsService = settingsService
        self.locationService = locationService
    }
    var shouldShowMap: Bool {
        let mapsEnabled: Bool = settingsService.usesMaps
        let locationEnabled: Bool
        switch locationService.locationState.value {
        case .located:
            locationEnabled = true
        default:
            locationEnabled = locationService.playerCity.value?.verified == true
        }
        return mapsEnabled && locationEnabled
    }


}
