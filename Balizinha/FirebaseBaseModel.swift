//
//  FirebaseBaseModel.swift
// Balizinha
//
//  Created by Bobby Ren on 5/13/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase
import RandomKit

class FirebaseBaseModel: NSObject {
    // Firebase objects have structure:
    // id: {
    //  key1: val1
    //  key2: val2
    //  ..
    // }

    var firebaseKey: String! // store id
    var firebaseRef: DatabaseReference? // url like lotsportz.firebase.com/model/id
    var dict: [String: Any]! // {key1: val1, key2: val2 ...}
    
    init(snapshot: DataSnapshot?) {
        if let snapshot = snapshot, snapshot.exists() {
            self.firebaseKey = snapshot.key
            self.firebaseRef = snapshot.ref
            self.dict = snapshot.value as? [String: AnyObject]
            
            // a new user doesn't have a dictionary
            if self.dict == nil {
                self.dict = [:]
            }
        }
    }
    
    override convenience init() {
        self.init(snapshot: nil)
        self.firebaseKey = String.random(using: &Xoroshiro.default)
    }

    // returns dict, or the value/contents of this object
    func toAnyObject() -> AnyObject {
        return self.dict as AnyObject
    }

    // returns unique id for this firebase object
    var id: String {
        return self.firebaseKey
    }
}

