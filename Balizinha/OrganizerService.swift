//
//  OrganizerService.swift
//  Balizinha
//
//  Created by Bobby Ren on 10/2/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase
import RxSwift

fileprivate var singleton: OrganizerService?
var _currentOrganizer: Organizer?
fileprivate var organizationRef: DatabaseReference?

class OrganizerService: NSObject {
    // MARK: - Singleton
    static var shared: OrganizerService {
        if singleton == nil {
            singleton = OrganizerService()

            // start observing and set _currentOrganizer
            singleton!.observableOrganizer?.take(1).subscribe(onNext: { (organizer) in
                _currentOrganizer = organizer
            })
        }

        return singleton!
    }
    
    class func resetOnLogout() {
        singleton = nil
    }
    
    var current: Organizer? {
        return _currentOrganizer
    }
    
    var observableOrganizer: Observable<Organizer>? {
        
        // TODO: how to handle this
        guard let existingUserId = firAuth.currentUser?.uid else { return nil }
        let newOrganizerRef: DatabaseReference = firRef.child("organizers").child(existingUserId)

        return Observable.create({ (observer) -> Disposable in
            newOrganizerRef.observe(.value) { (snapshot: DataSnapshot!) in
                observer.onNext(Organizer(snapshot: snapshot))
            }
            
            return Disposables.create()
        })
    }
    
    func createOrganizer(completion: ((Organizer?, NSError?) -> Void)? ) {
        
        guard let user = firAuth.currentUser else { return }
        let organizerRef = firRef.child("organizers")
        
        let existingUserId = user.uid
        let newOrganizerRef: DatabaseReference = organizerRef.child(existingUserId)
        let params = ["createdAt": Date().timeIntervalSince1970]
        newOrganizerRef.setValue(params) { (error, ref) in
            if let error = error as? NSError {
                print(error)
                completion?(nil, error)
            } else {
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    let organizer = Organizer(snapshot: snapshot)
                    completion?(organizer, nil)
                }, withCancel: { (error) in
                    completion?(nil, nil)
                })
            }
        }
    }
}
