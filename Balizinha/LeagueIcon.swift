//
//  LeagueIcon.swift
//  Balizinha
//
//  Created by Bobby Ren on 4/21/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class LeagueIcon: FirebaseModelIcon {

    override var photoUrl: String? {
        guard let league = object as? League else { return nil }
        return league.photoUrl
    }

}
