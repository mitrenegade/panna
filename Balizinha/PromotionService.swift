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
import PannaPay

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
    public init(reference: Reference = firRef, apiService: CloudAPIService = Globals.apiService) {
        ref = reference
        self.apiService = apiService
        super.init()
    }

    func withId(id: String, completion: @escaping ((Promotion?, NSError?)->Void)) {
        apiService.cloudFunction(functionName: "promotionWithId", method: "POST", params: ["promotionId": id]) { (result, error) in
            if let error = error as NSError? {
                completion(nil, error)
            } else if let dict = result as? [String: Any] {
                let promotion = Promotion(key: id, dict: dict)
                completion(promotion, nil)
            } else {
                completion(nil, nil)
            }
        }
    }
}
