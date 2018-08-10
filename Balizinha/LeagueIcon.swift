//
//  LeagueIcon.swift
//  Balizinha
//
//  Created by Bobby Ren on 4/21/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class LeagueIcon: FirebaseModelIcon {

    override func photoUrl(id: String?, completion: @escaping ((URL?)->Void)) {
        FirebaseImageService().leaguePhotoUrl(for: id) { (url) in
            print("PlayerIcon photoUrl: \(url)")
            DispatchQueue.main.async {
                completion(url)
            }
        }
    }

    override var initials: String? {
        guard let league = object as? League else { return nil }
        guard let name = league.name else { return nil }
        guard let char = name.uppercased().first else { return nil }
        return String(char)
    }
}
