//
//  VenueCell.swift
//  Panna
//
//  Created by Bobby Ren on 8/22/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class VenueCell: UITableViewCell {
    @IBOutlet weak var photoView: RAImageView?
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var buttonMap: UIButton?
    
    var venue: Venue?
    weak var presenter: UIViewController?

    func configure(with venue: Venue?) {
        guard let venue = venue else { return }
        self.venue = venue
        nameLabel.text = venue.name
        addressLabel.text = venue.shortString ?? nil
        
        // TODO: load venue image
        if let url = venue.photoUrl {
            photoView?.imageUrl = url
        } else {
            photoView?.isHidden = true
        }
        if venue.lat == nil || venue.lon == nil {
            buttonMap?.isHidden = true
        }
    }
    
    @IBAction func didClickMap(_ sender: UIButton?) {
        goToMapLocation()
    }

    private func goToMapLocation() {
        // https://developers.google.com/maps/documentation/urls/guide
        guard let venue = venue else { return }
        guard var urlComponents = URLComponents(string: "https://www.google.com/maps/search/") else { return }
        var queryParams: [String: String] = ["api": "1"]
        var query: String = ""
        if let place = venue.name {
            query = "\(query) \(place)"
        }
        if let shortString = venue.shortString {
            // open using city, state
            query = "\(query) \(shortString)"
        }
        queryParams["query"] = query
        if let placeId = venue.placeId {
            // placeId is used first if it can be found
            queryParams["query_place_id"] = placeId
        }
        urlComponents.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value)}
        
        if let url = urlComponents.url {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            LoggingService.shared.log(event: .ShowVenueLocationOnMap, info: queryParams)
        } else {
            LoggingService.shared.log(event: .ShowVenueLocationOnMap, info: ["error": "invalidUrl"].merging(queryParams, uniquingKeysWith: { old, new in new }))
        }
    }}

