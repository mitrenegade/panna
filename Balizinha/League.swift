//
//  League.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 4/9/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import Firebase
import RxSwift

class League: FirebaseBaseModel {
    var name: String? {
        get {
            return self.dict["name"] as? String
        }
        set {
            self.dict["name"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var city: String? {
        get {
            return self.dict["city"] as? String
        }
        set {
            self.dict["city"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var tags: [String] {
        get {
            return self.dict["tags"] as? [String] ?? []
        }
        set {
            self.dict["tags"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var info: String {
        get {
            if let val = self.dict["info"] as? String {
                return val
            }
            return ""
        }
        set {
            self.dict["info"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var photoUrl: String? {
        get {
            return self.dict["photoUrl"] as? String
        }
        set {
            self.dict["photoUrl"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var isPrivate: Bool {
        get {
            return self.dict["private"] as? Bool ?? false
        }
        set {
            self.dict["private"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var owner: String? {
        get {
            if let val = self.dict["owner"] as? String {
                return val
            }
            return nil
        }
    }
}

// MARK: - Tags
extension League {
    var tagString: String {
        var string: String = ""
        tags.forEach { tag in
            if string.isEmpty {
                string = tag
            } else {
                string = string + ", " + tag
            }
        }
        return string
    }
    
    class func tags(from tagString: String) -> [String] {
        let set = CharacterSet.alphanumerics.union([" "])
        let filtered = String(tagString.unicodeScalars.filter { set.contains($0) })
        let tokens = filtered.components(separatedBy: [" "])
        return tokens
    }
}


// MARK: - Rankings and info
extension League {
    var pointCount: Int {
        // point calculation: number of active games * 2 + number of past games + number of players
        return 12
    }
    
    var rating: Double {
        return 4.5
    }
}

fileprivate var airplaneModeLeagues: [League]?
let LEAGUE_ID_AIRPLANE_MODE = "5678"
extension League {
    //***************** hack: for test purposes only
    class func randomLeagues() -> [League] {
        guard airplaneModeLeagues == nil else {
            return airplaneModeLeagues!
        }
        
        let playerLeague = League()
        playerLeague.dict = ["name": "Balizinha Airplane", "city": playerLeague.randomPlace(), "tags": "fake, league, member, default", "info": "this is my airplane league"]
        playerLeague.firebaseKey = LEAGUE_ID_AIRPLANE_MODE

        let otherLeague = League()
        otherLeague.dict = ["name": "My Awesome League", "city": otherLeague.randomPlace(), "tags": "fake, league", "info": "this is another league in the sky"]
        otherLeague.firebaseKey = FirebaseAPIService.uniqueId()
        
        let leagues = [playerLeague, otherLeague]
        airplaneModeLeagues = leagues
        return leagues
    }
    
    fileprivate func randomPlace() -> String {
        let places = ["Boston", "New York", "Philadelphia", "Florida"]
        let random = Int(arc4random_uniform(UInt32(places.count)))
        return places[random]
    }
}
