//
//  SubscriptionsViewController.swift
//  Panna
//
//  Created by Bobby Ren on 2/21/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha
import RenderCloud
import RenderPay

class SubscriptionsViewController: UIViewController {
    let service: StripePaymentService = StripePaymentService(apiService: RenderAPIService())

    override func viewDidLoad() {
        super.viewDidLoad()

        loadSubscriptions()
    }
    
    private func loadSubscriptions() {
        var userId: String
        if AIRPLANE_MODE {
            userId = "123"
            service.apiService = MockCloudAPIService(uniqueId: "123", results: ["1": ["leagueId": "123", "status": "active"]])
        } else {
            guard let id = PlayerService.shared.current.value?.id else { return }
            userId = id
        }
        
        service.loadSubscriptions(userId: userId) { [weak self] results, error in
            print("results \(results)")
        }
    }
    
    @IBAction func didClickButton(_ sender: UIButton?) {
        var userId: String
        if AIRPLANE_MODE {
            userId = "123"
            service.apiService = MockCloudAPIService(uniqueId: "123", results: ["subscriptionId": "2", "subscription": ["leagueId": "123", "status": "active"]])
        } else {
            guard let id = PlayerService.shared.current.value?.id else { return }
            userId = id
        }
        let leagueId = "abc"
        let type = "owner"
        service.createSubscription(userId: userId, leagueId: leagueId, type: type) { [weak self] results, error in
            print("Received subscriptions \(results)")
        }
    }
}



// TODO: move this into RenderPay
extension StripePaymentService {
    func loadSubscriptions(userId: String, completion: (([String:[String: Any]]?, Error?)->Void)?) {
        let params = ["userId": userId]
        
        apiService?.cloudFunction(functionName: "getSubscriptions", method: "POST", params: params) { (result, error) in
            print("Result \(result) error \(error)")
            if let error = error {
                completion?(nil, error)
            } else {
                completion?(result as? [String:[String: Any]], nil)
            }
        }
    }
    
    func createSubscription(userId: String, leagueId: String, type: String, completion: (([String: Any]?, Error?)->Void)?) {
        let params = ["userId": userId, "leagueId": "123", "type": "owner"]
        apiService?.cloudFunction(functionName: "createSubscription", method: "POST", params: params) { (result, error) in
            print("Result \(result) error \(error)")
            if let error = error {
                completion?(nil, error)
            } else {
                completion?(result as? [String: Any], nil)
            }
        }
    }
}
