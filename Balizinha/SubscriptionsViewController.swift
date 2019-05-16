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

class SubscriptionsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        loadSubscriptions()
    }
    
    @IBAction func didClickButton(_ sender: UIButton?) {
        createSubscription()
    }

    func loadSubscriptions() {
        guard let userId = PlayerService.shared.current.value?.id else { return }
        let params = ["userId": userId]
        RenderAPIService().cloudFunction(functionName: "getSubscriptions", params: params) { (result, error) in
            print("Result \(result) error \(error)")
        }
    }
    
    func createSubscription() {
        guard let userId = PlayerService.shared.current.value?.id else { return }
        let params = ["userId": userId, "leagueId": "123", "type": "owner"]
        RenderAPIService().cloudFunction(functionName: "createSubscription", params: params) { (result, error) in
            print("Result \(result) error \(error)")
            
            self.loadSubscriptions()
        }
    }
}
