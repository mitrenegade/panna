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
import FBSDKLoginKit

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
        _currentPlayer = nil
    }

    // not technically part of Player because anonymous auth should not create a player
    class var isAnonymous: Bool {
        if AIRPLANE_MODE {
            return false
        }
        guard let user = currentUser else { return true }
        return user.isAnonymous
    }

    func createPlayer(name: String?, email: String?, city: String?, info: String?, photoUrl: String?, completion:@escaping (Player?, NSError?) -> Void) {
        
        guard let user = PlayerService.currentUser, !PlayerService.isAnonymous else { return }
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
            if let error = error as NSError? {
                print(error)
                completion(nil, error)
            } else {
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    guard snapshot.exists() else {
                        completion(nil, nil)
                        return
                    }
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

    class var currentUser: User? {
        return firAuth.currentUser
    }
    var current: Player? {
        _ = self.__once
        return _currentPlayer
    }
    
    var observedPlayer: Observable<Player>? {
        _ = self.__once
        
        guard let existingUserId = PlayerService.currentUser?.uid else { return nil }
        
        return Observable.create({ (observer) -> Disposable in
            let playerRef: DatabaseReference = playersRef!.child(existingUserId) // FIXME better optional unwrapping. what happens on logout?
            
            playerRef.observe(.value) { (snapshot: DataSnapshot) in
                guard snapshot.exists() else {
                    print("no player observed")
                    return
                }
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
            guard snapshot.exists() else {
                completion(nil)
                return
            }
            
            let player = Player(snapshot: snapshot)
            PlayerService.cachedNames[id] = player.name
            completion(player)
        })
    }
}

// Provider helpers
extension PlayerService {
    var hasFacebookProvider: Bool {
        guard let user = firAuth.currentUser else { return false }
        guard !user.providerData.isEmpty else { return false }
        for provider in user.providerData {
            if provider.providerID == "facebook.com" {
                return true
            }
        }
        return false
    }
}
// Profile and Facebook Photo
extension PlayerService {
    func storeUserInfo() {
        guard let user = PlayerService.currentUser else { return }
        print("signIn results: \(user) profile \(String(describing: user.photoURL)) \(String(describing: user.displayName))")
        createPlayer(name: user.displayName, email: user.email, city: nil, info: nil, photoUrl: user.photoURL?.absoluteString, completion: { (player, error) in
            _ = self.__once // invoke listener
        })
    }
    
    func downloadFacebookPhoto() {
        guard let player = current else { return }
        FBSDKProfile.loadCurrentProfile(completion: { (profile, error) in
            guard let profile = profile else {
                if let error = error as NSError?, error.code == 400 {
                    print("error \(error)")
                    AuthService.shared.logout()
                } // for other errors, ignore but don't load profile
                return
            }
            guard let photoUrl = profile.imageURL(for: FBSDKProfilePictureMode.square, size: CGSize(width: 100, height: 100)) else { return }
            DispatchQueue.global().async {
                guard let data = try? Data(contentsOf: photoUrl) else { return }
                guard let image = UIImage(data: data) else { return }
                FirebaseImageService.uploadImage(image: image, type: "player", uid: player.id, completion: { (url) in
                    if let url = url {
                        player.photoUrl = url
                    }
                })
            }
        })
        
    }
}
