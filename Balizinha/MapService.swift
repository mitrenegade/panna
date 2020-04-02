//
//  MapService.swift
//  Panna
//
//  Created by Bobby Ren on 9/18/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//
import Balizinha

class MapService {
    class func urlStringForSearch(venue: Venue?) -> (URL?, [String: Any]) {
        // https://developers.google.com/maps/documentation/urls/guide
        guard let venue = venue else { return (nil, [:]) }
        guard var urlComponents = URLComponents(string: "https://www.google.com/maps/search/") else { return (nil, [:]) }
        var queryParams: [String: String] = ["api": "1"]
        var query: String = ""
        if let place = venue.name {
            query = "\(query) \(place)"
        }
        if !venue.shortString.isEmpty {
            // open using city, state
            query = "\(query) \(venue.shortString)"
        }
        queryParams["query"] = query
        if let placeId = venue.placeId {
            // placeId is used first if it can be found
            queryParams["query_place_id"] = placeId
        }
        urlComponents.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value)}
        return (urlComponents.url, queryParams)
    }

    class func goToMapLocation(venue: Venue?) {
        let (url, params) = urlStringForSearch(venue: venue)
        if let url = url {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            LoggingService.shared.log(event: .ShowVenueLocationOnMap, info: params)
        } else {
            LoggingService.shared.log(event: .ShowVenueLocationOnMap, info: ["error": "invalidUrl"].merging(params, uniquingKeysWith: { old, new in new }))
        }
    }
    
    class func urlStringForDirections(event: Event?) -> (URL?, [String: Any]) {
        guard let event = event else { return (nil, [:])}
        guard var urlComponents = URLComponents(string: "https://www.google.com/maps/dir/") else { return (nil, [:]) }
        var queryParams: [String: String] = ["api": "1"]
        var destination: String = ""
        // TODO: incorporate venue
        if let place = event.place {
            destination = "\(destination) \(place)"
        }
        if let location = event.locationString {
            // open using city, state, or lat lon
            destination = "\(destination) \(location)"
        }
        queryParams["destination"] = destination
        urlComponents.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value)}
        return (urlComponents.url, queryParams)
    }
    
    class func goToMapDirections(_ event: Event?) {
        let (url, params) = urlStringForDirections(event: event)
        if let url = url {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            LoggingService.shared.log(event: .ShowMapDirections, info: params)
        } else {
            LoggingService.shared.log(event: .ShowMapDirections, info: ["error": "invalidUrl"].merging(params, uniquingKeysWith: { old, new in new }))
        }
    }
}
