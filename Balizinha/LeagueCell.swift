//
//  LeagueCell.swift
//  Balizinha
//
//  Created by Ren, Bobby on 4/30/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class LeagueCell: UITableViewCell {
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelPointCount: UILabel!
    @IBOutlet weak var labelPlayerCount: UILabel!
    @IBOutlet weak var labelGameCount: UILabel!
    @IBOutlet weak var labelRatingCount: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
