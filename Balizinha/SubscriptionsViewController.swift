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
        if AIRPLANE_MODE {
            service.apiService = MockCloudAPIService(uniqueId: "!23", results: ["results": "success"])
        }
        service.loadSubscriptions()
    }
    
    @IBAction func didClickButton(_ sender: UIButton?) {
        if AIRPLANE_MODE {
            service.apiService = MockCloudAPIService(uniqueId: "!23", results: ["results": "success"])
        }
        service.createSubscription()
    }
}

// TODO: move this into RenderPay
extension StripePaymentService {
    func loadSubscriptions() {
        guard let userId = PlayerService.shared.current.value?.id else { return }
        let params = ["userId": userId]
        
        apiService?.cloudFunction(functionName: "getSubscriptions", method: "POST", params: params) { (result, error) in
            print("Result \(result) error \(error)")
        }
    }
    
    func createSubscription() {
        guard let userId = PlayerService.shared.current.value?.id else { return }
        let params = ["userId": userId, "leagueId": "123", "type": "owner"]
        apiService?.cloudFunction(functionName: "createSubscription", method: "POST", params: params) { (result, error) in
            print("Result \(result) error \(error)")
            
            self.loadSubscriptions()
        }
    }
}
