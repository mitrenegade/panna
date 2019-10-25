//
//  MapServiceTests.swift
//  PannaTests
//
//  Created by Bobby Ren on 9/18/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import XCTest
import Balizinha
@testable import Panna

class MapServiceTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMapSearchWithVenueName() {
        let dict = ["name": "Name", "city": "City", "state": "State"]
        let venue = Venue(key: "abc", dict: dict)
        let (url, _) = MapService.urlStringForSearch(venue: venue)
        // result is something like https://www.google.com/maps/search/?api=1&query=%20Name%20City,%20State" but location of queries are not determinate
        XCTAssert(url!.absoluteString.contains("https://www.google.com/maps/search"))
        XCTAssert(url!.absoluteString.contains("api=1"))
        XCTAssert(url!.absoluteString.contains("query=%20Name%20City,%20State"))
    }

    func testMapSearchWithVenuePlaceId() {
        let dict = ["name": "Name", "placeId": "123"]
        let venue = Venue(key: "abc", dict: dict)
        let (url, _) = MapService.urlStringForSearch(venue: venue)
        // "https://www.google.com/maps/search/?api=1&query=%20Name&query_place_id=123"
        XCTAssert(url!.absoluteString.contains("https://www.google.com/maps/search"))
        XCTAssert(url!.absoluteString.contains("api=1"))
        XCTAssert(url!.absoluteString.contains("query_place_id=123"))
    }

    func testMapDirectionsWithEventName() {
        let dict = ["place": "Name", "city": "City", "state": "State"]
        let event = Event(key: "abc", dict: dict)
        let (url, _) = MapService.urlStringForDirections(event: event)
        // https://www.google.com/maps/dir/?destination=%20Name%20City,%20State&api=1
        XCTAssert(url!.absoluteString.contains("https://www.google.com/maps/dir"))
        XCTAssert(url!.absoluteString.contains("api=1"))
        XCTAssert(url!.absoluteString.contains("destination=%20Name%20City,%20State"))
    }
}
