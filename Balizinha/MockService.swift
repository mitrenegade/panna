//
//  MockService.swift
//  Panna
//
//  Created by Bobby Ren on 7/17/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha
import RenderCloud

class MockService: NSObject {
    static func mockLeague() -> League {
        return League(key: "abc", dict: ["name": "My league", "city": "Philadelphia", "info": "Airplane mode league", "ownerId": "1"])
    }

    static func mockPlayer() -> Player {
        return Player(key: "1", dict: ["name":"Philly Phanatic", "city": "Philadelphia", "email": "test@gmail.com"])
    }

    static func mockEventService() -> EventService {
        let eventDict: [String: Any] = ["name": "Test event",
                                        "status": "active",
                                        "startTime": (Date().timeIntervalSince1970 + Double(Int(arc4random_uniform(72)) * 3600))]
        let referenceSnapshot = MockDataSnapshot(exists: true,
                                                 key: "1",
                                                 value: eventDict,
                                                 ref: nil)
        let reference = MockDatabaseReference(snapshot: referenceSnapshot)
        let apiService = MockCloudAPIService(uniqueId: "abc", results: ["success": true])
        return EventService(reference: reference, apiService: apiService)
    }
}
