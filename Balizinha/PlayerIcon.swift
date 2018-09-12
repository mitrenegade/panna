//
//  PlayerIcon.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/19/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Balizinha

class PlayerIcon: FirebaseModelIcon {

    override func photoUrl(id: String?, completion: @escaping ((URL?) -> Void)) {
        FirebaseImageService().profileUrl(for: id) { (url) in
            DispatchQueue.main.async {
                completion(url)
            }
        }
    }
    
    override var initials: String? {
        guard let player = object as? Player else { return nil }
        guard let name = player.name else { return nil }
        guard let char = name.uppercased().first else { return nil }
        return String(char)
    }
}

