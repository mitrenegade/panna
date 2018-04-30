//
//  LeagueCell.swift
//  Balizinha
//
//  Created by Ren, Bobby on 4/30/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import AsyncImageView

class LeagueCell: UITableViewCell {
    
    @IBOutlet weak var icon: AsyncImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelPointCount: UILabel!
    @IBOutlet weak var labelPlayerCount: UILabel!
    @IBOutlet weak var labelGameCount: UILabel!
    @IBOutlet weak var labelRatingCount: UILabel!

    func setup(league: League) {
        icon.image = nil
        if let url = league.photoUrl {
            icon.imageURL = URL(string: url)
        } else {
            icon.imageURL = nil
        }
        var string = ""
        if let name = league.name {
            string = name + "\n\n"
        }
        string = "\(string)\(league.info)"
        labelName.text = string
        
        let pointCount = league.pointCount
        let playerCount = league.playerCount
        let rating = league.rating
        let eventCount = league.eventCount
        
        labelPointCount.text = "\(pointCount)"
        labelPlayerCount.text = "\(playerCount)"
        labelGameCount.text = "\(eventCount)"
        labelRatingCount.text = String(format: "%1.1f", rating)
    }
}
