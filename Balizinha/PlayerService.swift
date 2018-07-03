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
import RxOptional

class PlayerService: NSObject {
    // MARK: - Singleton
    static var shared: PlayerService = PlayerService()
    
    static var cachedNames: [String: String] = [:]
    
    fileprivate var disposeBag: DisposeBag

    let current: Variable<Player?> = Variable(nil)
    fileprivate let playersRef: DatabaseReference

    override init() {
        disposeBag = DisposeBag()
        playersRef = firRef.child("players") // this references the endpoint lotsports.firebase.com/players/
        playersRef.keepSynced(true)
        
        super.init()

        startAuthListener()
    }
    
    func startAuthListener() {
        AuthService.shared.loginState.asObservable().distinctUntilChanged().subscribe(onNext: {state in
            if state == .loggedIn, let user = AuthService.currentUser {
                print("PlayerService: log in state triggering player request with logged in user \(user.uid)")
                self.refreshCurrentPlayer()
            }
        }).disposed(by: disposeBag)
    }
    
    func refreshCurrentPlayer() {
        guard let user = AuthService.currentUser else { return }
        let playerRef: DatabaseReference = self.playersRef.child(user.uid)
        playerRef.observeSingleEvent(of: .value, with: { (snapshot) in
            guard snapshot.exists() else { return }
            
            let player = Player(snapshot: snapshot)
            print("PlayerService: loaded player \(player.id)")
            self.current.value = player
        })
    }
    
    class func resetOnLogout() {
        print("PlayerService resetOnLogout")
        shared.disposeBag = DisposeBag()
        shared.current.value = nil
        shared.startAuthListener()
    }

    
    func createPlayer(name: String?, email: String?, city: String?, info: String?, photoUrl: String?, completion:@escaping (Player?, NSError?) -> Void) {

        guard let user = AuthService.currentUser, !AuthService.isAnonymous else { return }
        let existingUserId = user.uid
        let newPlayerRef: DatabaseReference = playersRef.child(existingUserId)

        print("PlayerService createPlayer")

        var params: [String: Any] = [:]
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
                PlayerService.shared.current.asObservable().filterNil().take(1).subscribe(onNext: { player in
                    completion(player, nil)
                })
            }
        }
    }
    
    func withId(id: String, completion: @escaping ((Player?)->Void)) {
        let ref = playersRef.child(id)
        ref.observe(.value) { [weak self] (snapshot) in
            guard snapshot.exists() else {
                completion(nil)
                return
            }
            ref.removeAllObservers()
            let player = Player(snapshot: snapshot)
            PlayerService.cachedNames[id] = player.name
            completion(player)
        }
    }
}

// Profile and Facebook Photo
extension PlayerService {
    func storeUserInfo() {
        guard let user = AuthService.currentUser else { return }
        
        print("signIn results: \(user.uid) profile \(String(describing: user.photoURL)) \(String(describing: user.displayName))")
        createPlayer(name: user.displayName, email: user.email, city: nil, info: nil, photoUrl: user.photoURL?.absoluteString, completion: { [weak self] (player, error) in
            print("PlayerService storeUserInfo complete")
            if AuthService.shared.hasFacebookProvider == true {
                self?.downloadFacebookPhoto()
            }
        })
    }
    
    func downloadFacebookPhoto() {
        guard let player = current.value else { return }
        FBSDKProfile.loadCurrentProfile(completion: { (profile, error) in
            guard let profile = profile else {
                if let error = error as NSError?, error.code == 400 {
                    print("error \(error)")
                    AuthService.shared.logout()
                } // for other errors, ignore but don't load profile
                return
            }
            
            // update photoUrl if it doesn't already exist
            if player.photoUrl == nil, let photoUrl = profile.imageURL(for: FBSDKProfilePictureMode.square, size: CGSize(width: 100, height: 100)) {
                DispatchQueue.global().async {
                    guard let data = try? Data(contentsOf: photoUrl) else { return }
                    guard let image = UIImage(data: data) else { return }
                    FirebaseImageService.uploadImage(image: image, type: "player", uid: player.id, completion: { (url) in
                        if let url = url {
                            player.photoUrl = url
                        }
                    })
                }
            }
            if player.name == nil {
                if let name = profile.name {
                    player.name = name
                }
                else if let name = profile.firstName {
                    player.name = name
                }
            }
        })
        
    }
}
