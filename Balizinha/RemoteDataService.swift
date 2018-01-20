//
//  RemoteDataService.swift
//  Balizinha
//
//  Created by Bobby Ren on 9/10/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

fileprivate var singleton: RemoteDataService?
fileprivate var loggingRef: DatabaseReference?

class RemoteDataService: NSObject {
    private lazy var __once: () = {
        // firRef is the global firebase ref
        loggingRef = firRef.child("remoteData") // this creates a query on the endpoint /remoteData
    }()
    
    // MARK: - Singleton
    static var shared: RemoteDataService {
        if singleton == nil {
            singleton = RemoteDataService()
            singleton?.__once
        }
        
        return singleton!
    }
    
    var userId: String? // set a userId to listen for

    func getRecentUpdates() {
        guard let userId = userId else { return }
        guard let ref = loggingRef?.child(userId) else { return }
        ref.queryEqual(toValue: "true", childKey: "unread")
        ref.observe(.value) { (snapshot: DataSnapshot) in
            // this block is called for every result returned
        }
    }
    
    func post(userId: String, message: String) {
        guard let ref = loggingRef?.child(userId).childByAutoId() else { return }
        let params: [AnyHashable: Any] = ["message": message, "unread": true]
        ref.updateChildValues(params)
    }
    
    func setRead(userId: String, id: String) {
        guard let ref = loggingRef?.child(userId).child(id) else { return }
        ref.updateChildValues(["unread": false])
    }
}
