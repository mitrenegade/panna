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
}

