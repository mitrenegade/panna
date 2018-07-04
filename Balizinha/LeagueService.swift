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

fileprivate var _leagues: [String: League] = [:]
fileprivate var _playerLeagues: [String] = []

class LeagueService: NSObject {
    static let shared: LeagueService = LeagueService()
    var disposeBag: DisposeBag
    
    override init() {
        disposeBag = DisposeBag()
        super.init()
        
        guard !AIRPLANE_MODE else {
            return
        }
        
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
        guard !AIRPLANE_MODE else {
            let results = League.randomLeagues()
            completion(results)
            return
        }
        
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
                    _leagues[league.id] = league
                }
            }
            print("getLeagues results count: \(_leagues.count)")
            completion(Array(_leagues.values))
        }
    }
    
    func memberships(for league: League, completion: @escaping (([Membership]?)->Void)) {
        FirebaseAPIService().cloudFunction(functionName: "getPlayersForLeague", params: ["leagueId": league.id]) { (result, error) in
            guard error == nil else {
                //print("Players for league error \(error)")
                completion(nil)
                return
            }
            //print("Players for league results \(result)")
            if let dict = (result as? [String: Any])?["result"] as? [String: Any] {
                let roster = dict.compactMap({ (arg) -> Membership? in
                    let (key, val) = arg
                    if let status = val as? String {
                        return Membership(id: key, status: status)
                    } else {
                        return nil
                    }
                })
                completion(roster)
            } else {
                completion([])
            }
        }
    }

    func players(for league: League, completion: @escaping (([String]?)->Void)) {
        guard !AIRPLANE_MODE else {
            if league.id == LEAGUE_ID_AIRPLANE_MODE {
                completion([LEAGUE_ID_AIRPLANE_MODE])
            } else {
                completion(nil)
            }
            return
        }

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
    
    func events(for league: League, completion: @escaping (([Event]?)->Void)) {
        FirebaseAPIService().cloudFunction(functionName: "getEventsForLeague", params: ["leagueId": league.id]) { (result, error) in
            guard error == nil else {
                print("Events for league error \(error)")
                completion(nil)
                return
            }
            print("Events for league results \(result)")
            if let resultDict = result as? [String: Any], let eventDicts = resultDict["result"] as? [String:[String: Any]] {
                var events = [Event]()
                for (key, value) in eventDicts {
                    let event = Event(key: key, dict: value)
                    EventService.shared.cacheEvent(event: event)
                    events.append(event)
                }
                completion(events)
            } else {
                completion([])
            }
        }
    }
    
    func leagues(for player: Player, completion: @escaping (([String: Membership]?)->Void)) {
        guard !AIRPLANE_MODE else {
            completion([LEAGUE_ID_AIRPLANE_MODE: Membership(id: player.id, status: "member")])
            return
        }
        FirebaseAPIService().cloudFunction(functionName: "getLeaguesForPlayer", params: ["userId": player.id]) { (result, error) in
            guard error == nil else {
                //print("Leagues for player error \(error)")
                completion(nil)
                return
            }
            //print("Leagues for player results \(result)")
            if let dict = (result as? [String: Any])?["result"] as? [String: Any] {
                var result = [String:Membership]()
                for (leagueId, statusString) in dict {
                    let status = statusString as? String ?? "none"
                    result[leagueId] = Membership(id: player.id, status: status)
                }
                completion(result)
            } else {
                completion([:])
            }
        }
    }
    
    func playerIsIn(league: League) -> Bool {
        return _playerLeagues.contains(league.id)
    }
    
    func changeLeaguePlayerStatus(playerId: String, league: League, status: String, completion: @escaping ((_ result: Any?, _ error: Error?) -> Void)) {
        FirebaseAPIService().cloudFunction(functionName: "changeLeaguePlayerStatus", method: "POST", params: ["userId": playerId, "leagueId": league.id, "status": status]) { (result, error) in
            guard error == nil else {
                print("Player status change error \(error)")
                completion(nil, error)
                return
            }
            print("Player status change result \(result)")
            completion(result, nil)
        }
    }
    
    func withId(id: String, completion: @escaping ((League?)->Void)) {
        if let found = _leagues[id] {
            completion(found)
            return
        }

        let ref = firRef.child("leagues").child(id)
        ref.observe(.value) { [weak self] (snapshot) in
            guard snapshot.exists() else {
                completion(nil)
                return
            }
            ref.removeAllObservers()
            let league = League(snapshot: snapshot)
            _leagues[id] = league
            completion(league)
        }
    }
}
