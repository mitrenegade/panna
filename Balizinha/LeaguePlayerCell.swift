//
//  LeaguePlayerCell.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 5/7/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit

class LeaguePlayerCell: UITableViewCell {
    @IBOutlet weak var imagePhoto: RAImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelEmail: UILabel!
    @IBOutlet weak var labelCreated: UILabel!

    @IBOutlet weak var labelStatus: UILabel!
    
    func configure(player: Player, status: String) {
        labelName.text = player.name ?? "Anon"
        labelEmail.text = player.email
        labelCreated.text = player.createdAt?.dateString()
        
        if let urlString = player.photoUrl {
            self.updatePhoto(urlString: urlString)
        }
        
        labelStatus.text = status
    }
    
    func updatePhoto(urlString: String) {
        imagePhoto.image = nil
        imagePhoto.imageUrl = urlString
        imagePhoto.layer.cornerRadius = imagePhoto.frame.size.height / 2
    }
    
    func reset() {
        labelName.text = nil
        labelEmail.text = nil
        labelCreated.text = nil
    }
}
