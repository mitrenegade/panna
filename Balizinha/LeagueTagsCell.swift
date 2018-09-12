//
//  LeagueTagsCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 6/24/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class LeagueTagsCell: UITableViewCell {

    @IBOutlet weak var tagsView: ResizableTagView!
    @IBOutlet weak var constraintHeight: NSLayoutConstraint!

    func configure(league: League?) {
        guard let league = league else { return }
        let tags = league.tags
        tagsView.delegate = self
        tagsView.configureWithTags(tagStrings: tags, isPrivate: league.isPrivate)
    }
}

extension LeagueTagsCell: ResizableTagViewDelegate {
    func didUpdateHeight(height: CGFloat) {
        constraintHeight.constant = tagsView.frame.size.height
    }
}
