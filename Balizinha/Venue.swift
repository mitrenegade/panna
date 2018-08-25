//
//  Venue.swift
//  Panna
//
//  Created by Bobby Ren on 8/25/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class Venue: FirebaseBaseModel {
    public var name: String? {
        get {
            return self.dict["name"] as? String
        }
        set {
            self.dict["name"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

    public var street: String? {
        get {
            return self.dict["street"] as? String
        }
        set {
            self.dict["street"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var city: String? {
        get {
            return self.dict["city"] as? String
        }
        set {
            self.dict["city"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var state: String? {
        get {
            return self.dict["state"] as? String
        }
        set {
            self.dict["state"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var lat: Double? {
        get {
            return self.dict["lat"] as? Double
        }
        set {
            self.dict["lat"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var lon: Double? {
        get {
            return self.dict["lon"] as? Double
        }
        set {
            self.dict["lon"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    // creating a venue locally
    init(_ name: String?, _ street: String?, _ city: String?, _ state: String?, _ lat: Double?, _ lon: Double?) {
        let dict: [String: Any] = ["name": name, "street": street, "city": city, "state": state, "lat": lat, "lon": lon]
        super.init(key: "temp", dict: dict)
    }
}
