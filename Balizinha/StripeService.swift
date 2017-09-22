//
//  StripeService.swift
//  Balizinha
//
//  Created by Bobby Ren on 9/21/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Stripe

fileprivate var singleton: StripeService?

class StripeService: NSObject {
    static var shared: StripeService {
        if singleton == nil {
            singleton = StripeService()
        }
        
        return singleton!
    }

    let baseURL = URL(string: "https://us-central1-balizinha-dev.cloudfunctions.net/")
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        guard let url = self.baseURL?.appendingPathComponent("ephemeral_keys") else { return }
        
        let params = ["api_version": apiVersion]
        var request = URLRequest(url:url)
        request.httpMethod = "POST"
        try! request.httpBody = JSONSerialization.data(withJSONObject: params, options: [])
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in

            if let usableData = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: usableData, options: [])
                    completion(json as? [String: AnyObject], nil)
                } catch let error as Error {
                    print("error \(error)")
                    completion(nil, error)
                }
            }
            else if let error = error {
                completion(nil, error)
            }
        }
    }
}

extension StripeService: STPEphemeralKeyProvider {
    
}
