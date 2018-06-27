//
//  League.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 4/9/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import Firebase

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
    
    var tags: [String] {
        get {
            return self.dict["tags"] as? [String] ?? []
        }
        set {
            self.dict["tags"] = newValue
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
