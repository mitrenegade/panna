//
//  LeagueCell.swift
//  Balizinha
//
//  Created by Ren, Bobby on 4/30/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class LeagueCell: UITableViewCell {
    
    @IBOutlet weak var icon: RAImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelPointCount: UILabel?
    @IBOutlet weak var labelPlayerCount: UILabel?
    @IBOutlet weak var labelGameCount: UILabel?
    @IBOutlet weak var labelRatingCount: UILabel?
    @IBOutlet weak var labelCity: UILabel? // privacy also
    @IBOutlet weak var labelTags: UILabel? // level and other status strings
    @IBOutlet weak var labelInfo: UILabel? // catch phrase

    func configure(league: League) {
        icon.image = nil
        FirebaseImageService().leaguePhotoUrl(with: league.id) {[weak self] (url) in
            DispatchQueue.main.async {
                if let urlString = url?.absoluteString {
                    self?.icon.imageUrl = urlString
                } else {
                    self?.icon.imageUrl = nil
                    self?.icon.image = UIImage(named: "crest30")?.withRenderingMode(.alwaysTemplate)
                    self?.icon.tintColor = UIColor.white
                    self?.icon.backgroundColor = UIColor.darkGreen
                }
            }
        }
        labelName?.text = league.name ?? "Unknown league"
        labelCity?.text = league.city ?? "Location unspecified"
        labelTags?.text = league.tagString
        if !league.info.isEmpty {
            labelInfo?.text = "\"\(league.info)\""
        } else {
            labelInfo?.text = nil
        }
        
        let pointCount = league.pointCount
        let rating = 0 //league.rating

        labelPlayerCount?.text = "\(league.playerCount)"
        labelGameCount?.text = "\(league.eventCount)"

        labelPointCount?.text = "\(pointCount)"
        labelRatingCount?.text = String(format: "%1.1f", rating)
        
        // privacy
        if league.isPrivate, !LeagueService.shared.playerIsIn(league: league) {
            labelCity?.text = "Private"
            labelTags?.isHidden = true
            labelInfo?.isHidden = true
            
            icon.alpha = 0.5
            labelName.alpha = 0.5
            labelCity?.alpha = 0.5
        } else {
            labelTags?.isHidden = false
            labelInfo?.isHidden = false
            icon.alpha = 1
            labelName.alpha = 1
            labelCity?.alpha = 1
        }
    }
}
