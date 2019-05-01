//
//  PromotionService.swift
//  Balizinha
//
//  Created by Bobby Ren on 10/2/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseDatabase
import RenderCloud
import Balizinha

fileprivate var singleton: PromotionService?

class PromotionService: NSObject {
    // MARK: - Singleton
    static var shared: PromotionService {
        if singleton == nil {
            singleton = PromotionService()
            singleton?.__once
        }
        
        return singleton!
    }

    private lazy var __once: () = {
        // firRef is the global firebase ref
        let ref = firRef.child("promotions")
        ref.keepSynced(true)
    }()
    
    // service protocols
    fileprivate let ref: Reference
    fileprivate let apiService: CloudAPIService
    public init(reference: Reference = firRef, apiService: CloudAPIService = RenderAPIService()) {
        ref = reference
        self.apiService = apiService
        super.init()
    }

    func withId(id: String, completion: @escaping ((Promotion?, NSError?)->Void)) {
        let reference = ref.child(path: "promotions").child(path: id)
        reference.observeValue() { (snapshot) in
            guard snapshot.exists() else {
                completion(nil, NSError(domain: "balizinha.promo", code: 0, userInfo: ["reason": "Does not exist"]))
                return
            }

            reference.removeAllObservers()
            let promotion = Promotion(snapshot: snapshot)
            if promotion.active {
                completion(promotion, nil)
            }
            else {
                completion(nil, NSError(domain: "balizinha.promo", code: 1, userInfo: ["reason": "No longer active", "id": id]))
            }
        }
    }
}
