//
//  LeagueService.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 4/10/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import RxSwift

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
    
    func players(for league: League, completion: @escaping (([String]?)->Void)) {
        FirebaseAPIService().cloudFunction(functionName: "getPlayersForLeague", params: ["leagueId": league.id]) { (result, error) in
            guard error == nil else {
                //print("Players for league error \(error)")
                completion(nil)
                return
            }
            //print("Players for league results \(result)")
            if let dict = (result as? [String: Any])?["result"] as? [String: Bool] {
                let userIds = dict.filter({ (key, val) -> Bool in
                    return val
                }).map({ (key, val) -> String in
                    return key
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
    
    func withId(id: String, completion: @escaping ((League?)->Void)) {
        let ref = firRef.child("leagues")
        ref.child(id).observeSingleEvent(of: .value, with: { (snapshot) in
            guard snapshot.exists() else {
                completion(nil)
                return
            }
            
            let league = League(snapshot: snapshot)
            completion(league)
        })
    }
}
