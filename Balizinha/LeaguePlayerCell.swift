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
    
    func configure(player: Player, status: Membership.Status) {
        labelName.text = player.name ?? "Anon"
        labelEmail.text = player.email
        labelCreated.text = player.createdAt?.dateString()
        
        labelStatus.text = status.rawValue

        imagePhoto.image = nil
        imagePhoto.layer.cornerRadius = imagePhoto.frame.size.height / 2
        FirebaseImageService().profileUrl(for: player.id) {[weak self] (url) in
            if let url = url {
                DispatchQueue.main.async {
                    self?.imagePhoto.imageUrl = url.absoluteString
                }
            }
        }
    }

    func reset() {
        labelName.text = nil
        labelEmail.text = nil
        labelCreated.text = nil
        imagePhoto.image = nil
        imagePhoto.imageUrl = nil
    }
}
