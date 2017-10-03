//
//  PromotionService.swift
//  Balizinha
//
//  Created by Bobby Ren on 10/2/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

fileprivate var singleton: PromotionService?

class PromotionService: NSObject {
    // MARK: - Singleton
    static var shared: PromotionService {
        if singleton == nil {
            singleton = PromotionService()
        }
        
        return singleton!
    }

    func withId(id: String, completion: @escaping ((Promotion?)->Void)) {
        let ref = firRef.child("promotions/\(id)")
        
        ref.observeSingleEvent(of: .value, with: { (snapshot: DataSnapshot) in
            guard snapshot.exists() else {
                completion(nil)
                return
            }

            let promotion = Promotion(snapshot: snapshot)
            if promotion.active {
                completion(promotion)
            }
            else {
                completion(nil)
            }
        })
    }
}
