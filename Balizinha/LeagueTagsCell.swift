//
//  LeagueTagsCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 6/24/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class LeagueTagsCell: UITableViewCell {

    @IBOutlet weak var tagsView: ResizableTagView!

    func configure(league: League?) {
        guard let league = league else { return }
        let tags = league.tags
        tagsView.configureWithTags(tagStrings: tags)
    }
}
