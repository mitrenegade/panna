//
//  PlayerService.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/5/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

fileprivate var singleton: PlayerService?
var _currentPlayer: Player?

class PlayerService: NSObject {
    // MARK: - Singleton
    static var shared: PlayerService {
        if singleton == nil {
            singleton = PlayerService()
        }
        
        return singleton!
    }

    class func resetOnLogout() {
        singleton = nil
    }

    func createPlayer(name: String?, email: String?, city: String?, info: String?, photoUrl: String?, completion:@escaping (Player?, NSError?) -> Void) {
        
        guard let user = firAuth?.currentUser else { return }
        
        let playerRef = firRef.child("players") // this references the endpoint lotsports.firebase.com/events/
        let existingUserId = user.uid
        let newPlayerRef: FIRDatabaseReference = playerRef.child(existingUserId)
        
        var params: [String: Any] = ["createdAt": Date().timeIntervalSince1970]
        if let name = name {
            params["name"] = name
        }
        if let email = email {
            params["email"] = email
        }
        if let city = city {
            params["city"] = city
        }
        if let info = info {
            params["info"] = info
        }
        if let photoUrl = photoUrl {
            params["photoUrl"] = photoUrl
        }
        
        newPlayerRef.setValue(params) { (error, ref) in
            if let error = error as? NSError {
                print(error)
                completion(nil, error)
            } else {
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    let player = Player(snapshot: snapshot)
                    completion(player, nil)
                }, withCancel: { (error) in
                    completion(nil, nil)
                })
            }
        }
    }

    private lazy var __once: () = {
        // firRef is the global firebase ref
        let playersRef = firRef.child("players") // this references the endpoint lotsports.firebase.com/players/
        let existingUserId = firAuth?.currentUser?.uid
        let playerRef: FIRDatabaseReference = playersRef.child(existingUserId!) // FIXME better optional unwrapping. what happens on logout?
        
        playerRef.observe(.value) { (snapshot: FIRDataSnapshot!) in
            _currentPlayer = Player(snapshot: snapshot)
        }
    }()

    var current: Player? {
        _ = self.__once
        return _currentPlayer
    }
}
