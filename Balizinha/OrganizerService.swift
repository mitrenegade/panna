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
    let disposeBag = DisposeBag()
    var loading: Bool = true
    static var shared: OrganizerService {
        if singleton == nil {
            singleton = OrganizerService()

            let organizerRef = firRef.child("organizers")
            organizerRef.keepSynced(true)
            
            // start observing and set _currentOrganizer
            singleton!.startListeningForOrganizer()
        }

        return singleton!
    }
    
    class func resetOnLogout() {
        singleton = nil
        _currentOrganizer = nil
    }
    
    var current: Organizer? {
        return _currentOrganizer
    }
    
    var observableOrganizer: Observable<Organizer>? {
        
        // TODO: how to handle this
        guard let existingUserId = PlayerService.currentUser?.uid else { return nil }
        let newOrganizerRef: DatabaseReference = firRef.child("organizers").child(existingUserId)

        return Observable.create({ (observer) -> Disposable in
            newOrganizerRef.observe(.value) {[weak self] (snapshot: DataSnapshot) in
                self?.loading = false
                if snapshot.exists() {
                    observer.onNext(Organizer(snapshot: snapshot))
                } else {
                    observer.onNext(Organizer.nilOrganizer)
                }
            }
            
            return Disposables.create()
        })
    }
    
    func startListeningForOrganizer() {
        observableOrganizer?.subscribe(onNext: { (organizer) in
            if organizer == Organizer.nilOrganizer {
                _currentOrganizer = nil
            } else {
                _currentOrganizer = organizer
            }
        }).disposed(by: disposeBag)
    }
    
    func createOrganizer(completion: ((Organizer?, Error?) -> Void)? ) {
        
        guard let user = PlayerService.currentUser else { return }
        guard let current = PlayerService.shared.current else { return }
        let organizerRef = firRef.child("organizers")
        
        let existingUserId = user.uid
        let newOrganizerRef: DatabaseReference = organizerRef.child(existingUserId)
        let params: [AnyHashable: Any] = ["createdAt": Date().timeIntervalSince1970, "name": current.name ?? current.email ?? ""]
        newOrganizerRef.setValue(params) { (error, ref) in
            if let error = error {
                print(error)
                completion?(nil, error)
            } else {
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    guard snapshot.exists() else {
                        completion?(Organizer.nilOrganizer, nil)
                        return
                    }
                    let organizer = Organizer(snapshot: snapshot)
                    completion?(organizer, nil)
                }, withCancel: { (error) in
                    completion?(nil, nil)
                })
            }
        }
    }
    
    func requestOrganizerAccess(completion: ((Organizer?, Error?) -> Void)? ) {
        
        guard let user = PlayerService.currentUser, let current = PlayerService.shared.current else {
            completion?(nil, nil)
            return
        }
        let organizerRef = firRef.child("organizers")
        
        let existingUserId = user.uid
        let newOrganizerRef: DatabaseReference = organizerRef.child(existingUserId)
        let params: [AnyHashable: Any] = ["createdAt": Date().timeIntervalSince1970, "name": current.name ?? current.email ?? "", "status": "pending"]
        newOrganizerRef.setValue(params) { (error, ref) in
            if let error = error {
                print(error)
                completion?(nil, error)
            } else {
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    guard snapshot.exists() else {
                        completion?(Organizer.nilOrganizer, nil)
                        return
                    }
                    let organizer = Organizer(snapshot: snapshot)
                    completion?(organizer, nil)
                }, withCancel: { (error) in
                    completion?(nil, nil)
                })
            }
        }
    }
}
