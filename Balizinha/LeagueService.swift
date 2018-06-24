//
//  LeagueService.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 4/10/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import RxSwift
import Firebase

fileprivate var _leagues: [League] = []
fileprivate var _playerLeagues: [String] = []

class LeagueService: NSObject {
    static let shared: LeagueService = LeagueService()
    var disposeBag: DisposeBag
    
    override init() {
        disposeBag = DisposeBag()
        super.init()
        
        PlayerService.shared.current.asObservable().distinctUntilChanged().subscribe(onNext: { [weak self] player in
            guard let player = player else { return }
            
            self?.leagues(for: player, completion: { (results) in
                print("Player leagues: \(results)")
                if let ids = results as? [String] {
                    _playerLeagues.removeAll()
                    _playerLeagues.append(contentsOf: ids)
                }
            })
        }).disposed(by: disposeBag)
    }
    
    class func resetOnLogout() {
        shared.disposeBag = DisposeBag()
    }
    
    func create(name: String, city: String, info: String, completion: @escaping ((_ result: Any?, _ error: Error?)->Void)) {
        guard let user = AuthService.currentUser else { return }
        let params = ["name": name, "city": city, "info": info, "userId": user.uid]
        FirebaseAPIService().cloudFunction(functionName: "createLeague", method: "POST", params: params, completion: { (result, error) in
            guard error == nil else {
                print("League creation error \(error)")
                completion(nil, error)
                return
            }
            print("League creation result \(result)")
            completion(result, nil)
        })
    }
    
    func join(league: League, completion: @escaping ((_ result: Any?, _ error: Error?) -> Void)) {
        guard let user = AuthService.currentUser else { return }
        FirebaseAPIService().cloudFunction(functionName: "joinLeague", method: "POST", params: ["userId": user.uid, "leagueId": league.id]) { (result, error) in
            guard error == nil else {
                print("League join error \(error)")
                completion(nil, error)
                return
            }
            print("League join result \(result)")
            completion(result, nil)
        }
    }
    
    func getLeagues(completion: @escaping (_ results: [League]) -> Void) {
        let queryRef = firRef.child("leagues")
        
        queryRef.observeSingleEvent(of: .value) { (snapshot: DataSnapshot) in
            // this block is called for every result returned
            guard snapshot.exists() else {
                completion([])
                return
            }
            _leagues.removeAll()
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                for dict: DataSnapshot in allObjects {
                    guard dict.exists() else { continue }
                    let league = League(snapshot: dict)
                    _leagues.append(league)
                }
            }
            print("getLeagues results count: \(_leagues.count)")
            completion(_leagues)
        }
    }
    
    func players(for league: League, completion: @escaping (([String]?)->Void)) {
        FirebaseAPIService().cloudFunction(functionName: "getPlayersForLeague", params: ["leagueId": league.id]) { (result, error) in
            guard error == nil else {
                //print("Players for league error \(error)")
                completion(nil)
                return
            }
            //print("Players for league results \(result)")
            if let dict = (result as? [String: Any])?["result"] as? [String: Any] {
                let userIds = dict.compactMap({ (arg) -> String? in
                    let (key, val) = arg
                    if let status = val as? String, (status == "member" || status == "owner" || status == "organizer") {
                        return key
                    } else {
                        return nil
                    }
                })
                completion(userIds)
            } else {
                completion([])
            }
        }
    }
    
    func leagues(for player: Player, completion: @escaping (([String]?)->Void)) {
        FirebaseAPIService().cloudFunction(functionName: "getLeaguesForPlayer", params: ["userId": player.id]) { (result, error) in
            guard error == nil else {
                //print("Leagues for player error \(error)")
                completion(nil)
                return
            }
            //print("Leagues for player results \(result)")
            if let dict = (result as? [String: Any])?["result"] as? [String: Any] {
                let userIds = Array(dict.keys)
                completion(userIds)
            } else {
                completion([])
            }
        }
    }
    
    func playerIsIn(league: League) -> Bool {
        return _playerLeagues.contains(league.id)
    }
    
    func withId(id: String, completion: @escaping ((League?)->Void)) {
        if let found = _leagues.first(where: { (league) -> Bool in
            return league.id == id
        }) {
            completion(found)
            return
        }

        let ref = firRef.child("leagues")
        ref.child(id).observeSingleEvent(of: .value, with: { (snapshot) in
            guard snapshot.exists() else {
                completion(nil)
                return
            }
            
            let league = League(snapshot: snapshot)
            _leagues.append(league)
            completion(league)
        })
    }
}
