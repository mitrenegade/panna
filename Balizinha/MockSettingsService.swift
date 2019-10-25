//
//  MockSettingsService.swift
//  Panna
//
//  Created by Bobby Ren on 10/14/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import UIKit

class MockSettingsService: SettingsService {
    var mockSettings: [SettingsKey: Any] = [:]
    
    override var usesMaps: Bool {
        return mockSettings[SettingsKey.maps] as? Bool ?? false
    }
}
