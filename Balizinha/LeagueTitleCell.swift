//
//  LeagueTitleCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 6/24/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class LeagueTitleCell: UITableViewCell {
    @IBOutlet weak var logoView: RAImageView!
    @IBOutlet weak var labelCity: UILabel!
    @IBOutlet weak var labelName: UILabel!
    
    func configure(league: League?) {
        guard let league = league else { return }
        labelCity.text = league.city
        labelName.text = league.name
        logoView.image = nil
        FirebaseImageService().leaguePhotoUrl(with: league.id) {[weak self] (url) in
            if let url = url {
                DispatchQueue.main.async {
                    self?.logoView.imageUrl = url.absoluteString
                }
            } else {
                DispatchQueue.main.async {
                    self?.logoView.imageUrl = nil
                    self?.logoView.image = UIImage(named: "crestLarge")?.withRenderingMode(.alwaysTemplate)
                    self?.logoView.tintColor = UIColor.white
                    self?.logoView.backgroundColor = PannaUI.iconBackground
                }
            }
        }
    }
}
