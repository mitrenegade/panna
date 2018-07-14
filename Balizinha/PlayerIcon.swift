//
//  PlayerIcon.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/19/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

class PlayerIcon: FirebaseModelIcon {

    override func photoUrl(id: String?, completion: @escaping ((URL?) -> Void)) {
        FirebaseImageService().profileUrl(for: id) { (url) in
            print("PlayerIcon photoUrl: \(url)")
            DispatchQueue.main.async {
                completion(url)
            }
        }
    }
}

