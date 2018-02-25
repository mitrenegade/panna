//
//  Player.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/5/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

class Player: FirebaseBaseModel {
//    var service = EventService.shared

    var name: String? {
        get {
            guard let dict = self.dict else { return nil }
            if let val = dict["name"] as? String {
                return val
            }
            return nil
        }
        set {
            self.dict["name"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

    var email: String? {
        get {
            guard let dict = self.dict else { return nil }
            if let val = dict["email"] as? String {
                return val
            }
            return nil
        }
        set {
            self.dict["email"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var city: String? {
        get {
            guard let dict = self.dict else { return nil }
            if let val = dict["city"] as? String {
                return val
            }
            return nil
        }
        set {
            self.dict["city"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var photoUrl: String? {
        get {
            guard let dict = self.dict else { return nil }
            if let val = dict["photoUrl"] as? String {
                return val
            }
            return nil
        }
        set {
            self.dict["photoUrl"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

    var info: String? {
        get {
            guard let dict = self.dict else { return nil }
            if let val = dict["info"] as? String {
                return val
            }
            return nil
        }
        set {
            self.dict["info"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var isInactive: Bool {
        return false
    }
    
    // MARK: - Preferred Status
    var promotionId: String? {
        get {
            return self.dict?["promotionId"] as? String
        }
        set {
            self.dict["promotionId"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

    // MARK: - Push
    var fcmToken: String? {
        get {
            return self.dict?["fcmToken"] as? String
        }
        set {
            self.dict["fcmToken"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    // MARK: - Location
    var lat: Double? {
        get {
            return self.dict?["lat"] as? Double
        }
        set {
            self.dict["lat"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

    var lon: Double? {
        get {
            return self.dict?["lon"] as? Double
        }
        set {
            self.dict["lon"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

    var lastLocationTimestamp: Date? {
        get {
            if let val = self.dict["lastLocationTimestamp"] as? TimeInterval {
                return Date(timeIntervalSince1970: val)
            }
            return nil
        }
        set {
            self.dict["lastLocationTimestamp"] = newValue?.timeIntervalSince1970
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    
    var createdAt: Date? {
        if let val = self.dict["createdAt"] as? TimeInterval {
            let time1970: TimeInterval = 1517606802
            if val > time1970 * 10.0 {
                return Date(timeIntervalSince1970: (val / 1000.0))
            } else {
                return Date(timeIntervalSince1970: val)
            }
        }
        return nil
    }
    
    var os: String? {
        get {
            return self.dict["OS"] as? String
        }
        set {
            self.dict["OS"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
}

