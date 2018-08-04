//
//  FacebookService.swift
//  Balizinha
//
//  Created by Bobby Ren on 8/3/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class FacebookService: NSObject {
    static func downloadFacebookInfo(completion: ((UIImage?, String?, Error?)->Void)?) {
        guard let player = PlayerService.shared.current.value else { return }
        //        guard player.photoUrl == nil || player.name == nil else { return }
        FBSDKProfile.loadCurrentProfile(completion: { (profile, error) in
            guard let profile = profile else {
                completion?(nil, nil, error)
                return
            }
            
            // update photoUrl if it doesn't already exist
            if let photoUrl = profile.imageURL(for: FBSDKProfilePictureMode.square, size: CGSize(width: 100, height: 100)) {
                DispatchQueue.main.async {
                    guard let data = try? Data(contentsOf: photoUrl) else { return }
                    guard let image = UIImage(data: data) else { return }
                    FirebaseImageService.uploadImage(image: image, type: .player, uid: player.id, completion: { (url) in
                        if let name = profile.name {
                            completion?(image, name, nil)
                        }
                        else if let name = profile.firstName {
                            completion?(image, name, nil)
                        }
                    })
                }
            } else {
                if let name = profile.name {
                    completion?(nil, name, nil)
                }
                else if let name = profile.firstName {
                    completion?(nil, name, nil)
                }
            }
        })
    }
}
