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
            self?.refreshPlayerLeagues(completion: nil)
        }).disposed(by: disposeBag)
    }
    
    func refreshPlayerLeagues(completion: (([String]?)->Void)?) {
        // loads current player's leagues
        guard let player = PlayerService.shared.current.value else { return }
        leagueMemberships(for: player, completion: { (results) in
            print("Player leagues: \(results)")
            if let roster = results {
                _playerLeagues = roster.compactMap({ (key, status) -> String? in
                    if status != .none {
                        return key
                    } else {
                        return nil
                    }
                })
            }
            completion?(_playerLeagues)
        })
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
        FirebaseAPIService().cloudFunction(functionName: "joinLeaveLeagueV1_4", method: "POST", params: ["userId": user.uid, "leagueId": league.id, "isJoin": true]) { (result, error) in
            guard error == nil else {
                print("League join error \(error)")
                completion(nil, error)
                return
            }
            print("League join result \(result)")
            completion(result, nil)
        }
    }
    
    func leave(league: League, completion: @escaping ((_ result: Any?, _ error: Error?) -> Void)) {
        guard let user = AuthService.currentUser else { return }
        FirebaseAPIService().cloudFunction(functionName: "joinLeaveLeagueV1_4", method: "POST", params: ["userId": user.uid, "leagueId": league.id, "isJoin": false]) { (result, error) in
            guard error == nil else {
                print("League leave error \(error)")
                completion(nil, error)
                return
            }
            print("League leave result \(result)")
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
        queryRef.observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot.exists() else {
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
                    guard event.active else { return } // filters
                    EventService.shared.cacheEvent(event: event)
                    events.append(event)
                }
                completion(events)
            } else {
                completion([])
            }
        }
    }
    
    func leagueMemberships(for player: Player, completion: @escaping (([String: Membership.Status]?)->Void)) {
        guard !AIRPLANE_MODE else {
            completion([LEAGUE_ID_AIRPLANE_MODE: Membership.Status.member])
            return
        }
        FirebaseAPIService().cloudFunction(functionName: "getLeaguesForPlayer", params: ["userId": player.id]) { (result, error) in
            guard error == nil else {
                //print("Leagues for player error \(error)")
                completion(nil)
                return
            }
            print("Leagues for player \(player.id) results \(result)")
            if let dict = (result as? [String: Any])?["result"] as? [String: Any] {
                var result = [String:Membership.Status]()
                for (leagueId, statusString) in dict {
                    var status = statusString as? String ?? "none"
                    // for api v1.4, some users were set to true
                    if let legacyValue = statusString as? Bool, legacyValue == true {
                        status = "member"
                    }
                    if let membershipStatus = Membership.Status(rawValue: status) {
                        result[leagueId] = membershipStatus
                    }
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
