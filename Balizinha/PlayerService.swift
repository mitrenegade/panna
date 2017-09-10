//
//  PlayerService.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/5/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase
import RxSwift

fileprivate var singleton: PlayerService?
var _currentPlayer: Player?
fileprivate var playersRef: DatabaseReference?

class PlayerService: NSObject {
    // MARK: - Singleton
    static var shared: PlayerService {
        if singleton == nil {
            singleton = PlayerService()
            singleton?.__once
        }
        
        return singleton!
    }
    
    static var cachedNames: [String: String] = [:]

    class func resetOnLogout() {
        singleton = nil
    }

    func createPlayer(name: String?, email: String?, city: String?, info: String?, photoUrl: String?, completion:@escaping (Player?, NSError?) -> Void) {
        
        guard let user = firAuth.currentUser else { return }
        guard let playersRef = playersRef else { return }
        
        let existingUserId = user.uid
        let newPlayerRef: DatabaseReference = playersRef.child(existingUserId)
        
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
                    PlayerService.cachedNames[player.id] = player.name
                    completion(player, nil)
                }, withCancel: { (error) in
                    completion(nil, nil)
                })
            }
        }
    }

    private lazy var __once: () = {
        // firRef is the global firebase ref
        playersRef = firRef.child("players") // this references the endpoint lotsports.firebase.com/players/
        playersRef!.keepSynced(true)
    }()

    var current: Player? {
        _ = self.__once
        return _currentPlayer
    }
    
    var observedPlayer: Observable<Player> {
        _ = self.__once
        
        return Observable.create({ (observer) -> Disposable in
            let existingUserId = firAuth.currentUser?.uid
            let playerRef: DatabaseReference = playersRef!.child(existingUserId!) // FIXME better optional unwrapping. what happens on logout?
            
            playerRef.observe(.value) { (snapshot: DataSnapshot!) in
                _currentPlayer = Player(snapshot: snapshot)
                if let player = _currentPlayer {
                    observer.onNext(player)
                }
            }

            return Disposables.create()
        })
    }
    
    func withId(id: String, completion: @escaping ((Player?)->Void)) {
        guard let playersRef = playersRef else { return }
        playersRef.child(id).observeSingleEvent(of: .value, with: { (snapshot) in
            let player = Player(snapshot: snapshot)
            PlayerService.cachedNames[id] = player.name
            completion(player)
        })
    }
}
