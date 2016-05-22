//
//  FirebaseBaseModel.swift
//  LotSportz
//
//  Created by Bobby Ren on 5/13/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

class FirebaseBaseModel: NSObject {
    // Firebase objects have structure:
    // id: {
    //  key1: val1
    //  key2: val2
    //  ..
    // }

    var firebaseKey: String! // store id
    var firRef: FIRDatabaseReference? // url like lotsportz.firebase.com/model/id
    var dict: [String: AnyObject]! // {key1: val1, key2: val2 ...}
    
    init(snapshot: FIRDataSnapshot) {
        self.firebaseKey = snapshot.key
        self.firRef = snapshot.ref
        self.dict = snapshot.value as? [String: AnyObject]
    }

    // returns dict, or the value/contents of this object
    func toAnyObject() -> AnyObject {
        return self.dict
    }

    // returns unique id for this firebase object
    func id() -> String {
        return self.firebaseKey
    }
    
}
