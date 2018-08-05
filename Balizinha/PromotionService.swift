//
//  PromotionService.swift
//  Balizinha
//
//  Created by Bobby Ren on 10/2/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseDatabase

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

    func withId(id: String, completion: @escaping ((Promotion?, NSError?)->Void)) {
        let ref = firRef.child("promotions").child(id)
        ref.observe(.value) { [weak self] (snapshot) in
            guard snapshot.exists() else {
                completion(nil, NSError(domain: "balizinha.promo", code: 0, userInfo: ["reason": "Does not exist"]))
                return
            }

            ref.removeAllObservers()
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
