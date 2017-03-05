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
//    var service = EventService.sharedInstance()

    var name: String? {
        get {
            if let val = self.dict["name"] as? String {
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
            if let val = self.dict["email"] as? String {
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
            if let val = self.dict["city"] as? String {
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
            if let val = self.dict["photoUrl"] as? String {
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
            if let val = self.dict["info"] as? String {
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
}
