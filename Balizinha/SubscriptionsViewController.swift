//
//  SubscriptionsViewController.swift
//  Panna
//
//  Created by Bobby Ren on 2/21/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//
// TODO: flow for paying:
// Display all leagues for the owner.
// Display subscription status, which also translates to league tier
// On selection of a league, the user is prompted for confirmation.
// If the user doesn't have an active stripe payment method, they are shown an error and directed to the same payment view as regular players.
// After confirmation of the subscription, the leagues are reloaded, and the new one is updated with new subscription status.
//
// For a new owner who does not have any leagues:
// TODO: how to create a new league for an owner?
// Same as new subscription?

import UIKit
import Balizinha
import RenderCloud
import RenderPay

class SubscriptionsViewController: UIViewController {
    let service: StripePaymentService = StripePaymentService(apiService: RenderAPIService())
    
    @IBOutlet weak var tableView: UITableView!
    var isLoading: Bool = true
    
    var subscriptions: [Subscription] = []
    var leagues: [League] = []
    var subscriptionForLeague: [String: Subscription] = [:]
    var playerLeagues: [League] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didClickAdd(sender:)))

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80

        loadAllData()
    }
    
    private func loadAllData() {
        let dispatchGroup = DispatchGroup()
        
        showLoadingIndicator()

        dispatchGroup.enter()
        loadLeagues {
            dispatchGroup.leave()
        }
        
        loadSubscriptions() {
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            self.hideLoadingIndicator()
            self.reloadTableData()
        }
    }
    
    private func loadLeagues(completion:(()->Void)?) {
        guard let player = PlayerService.shared.current.value else {
            return
        }
        
        playerLeagues.removeAll()
        
        LeagueService.shared.leagueMemberships(for: player) { [weak self] (roster) in
            guard let ids = roster else {
                return
            }
            
            var organizerCount = 0
            for (leagueId, status) in ids {
                guard status == Membership.Status.organizer else { continue }
                organizerCount += 1
                LeagueService.shared.withId(id: leagueId, completion: { [weak self] (league) in
                    if let league = league as? League {
                        self?.playerLeagues.append(league)
                        DispatchQueue.main.async {
                            self?.reloadTableData()
                        }
                    }
                })
            }
        }
    }

    private func loadSubscriptions(completion: (()->Void)?) {
        var userId: String
        if AIRPLANE_MODE {
            userId = "123"
            service.apiService = MockCloudAPIService(uniqueId: "123", results: ["1": ["leagueId": "123", "status": "active"]])
        } else {
            guard let id = PlayerService.shared.current.value?.id else { return }
            userId = id
        }
        
        service.loadSubscriptions(userId: userId) { [weak self] results, error in
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    self?.simpleAlert("Error loading subscriptions", defaultMessage: nil, error: error)
                } else if let subscriptions = results {
                    // TODO: convert subscriptions
                    //self?.subscriptions = subscriptions
                    self?.loadLeaguesForSubscriptions()
                }
            }
        }
    }
    
    private func loadLeaguesForSubscriptions() {
        let group = DispatchGroup()
        leagues.removeAll()
        for subscription in subscriptions {
            guard let leagueId = subscription.leagueId else { continue }
            group.enter()
            LeagueService.shared.withId(id: leagueId) { [weak self] (league) in
                if let league = league as? League {
                    print("Loaded league \(leagueId)")
                    self?.leagues.append(league)
                    self?.subscriptionForLeague[leagueId] = subscription
                } else {
                    print("No league for \(leagueId)")
                }
                group.leave()
            }
        }
        group.notify(queue: DispatchQueue.main) {
            self.isLoading = false
            self.reloadTableData()
        }
    }
    
    @objc private func didClickAdd(sender: Any?) {
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
            if let error = error as NSError? {
                self?.simpleAlert("Error creating subscription", defaultMessage: nil, error: error)
            } else if let subscriptions = results {
                // TODO: must convert
                //self?.subscriptions = subscriptions
                self?.reloadTableData()
            }
        }
    }
}


extension SubscriptionsViewController: UITableViewDataSource {
    fileprivate func reloadTableData() {
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !isLoading else {
            return 1
        }
        
        return leagues.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !isLoading else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath)
            return cell
        }
        let cell : SubscriptionCell = tableView.dequeueReusableCell(withIdentifier: "SubscriptionCell", for: indexPath) as! SubscriptionCell
        let row = indexPath.row
        let league = leagues[row]
        guard let subscription = subscriptionForLeague[league.id] else {
            return cell
        }
        cell.configure(league: league, subscription: subscription)
        return cell
    }
}

// TODO: move this into Balizinha
enum SubscriptionType: String {
    case owner
    case membership
    case none
}
class Subscription: FirebaseBaseModel {
    public var leagueId: String? {
        get {
            return self.dict["leagueId"] as? String
        }
        set {
            //            update(key: "league", value: newValue)
        }
    }
    
    public var type: SubscriptionType {
        get {
            if let string = self.dict["type"] as? String, let newType = SubscriptionType(rawValue: string) {
                return newType
            }
            return .none
        }
        set {
            //            update(key: "type", value: newValue)
        }
    }
    
    public var status: String? {
        get {
            return self.dict["status"] as? String
        }
        set {
            //            update(key: "league", value: newValue)
        }
    }
    
    // amount in dollars
    public var amount: Double? {
        get {
            guard let subscription = dict["subscription"] as? [String: Any],
            let plan = subscription["plan"] as? [String: Any],
            let amount = plan["amount"] as? Double else {
                    return nil
            }
            return amount / 100.0
        }
        set {
            //            update(key: "league", value: newValue)
        }
    }
}


// TODO: move this into RenderPay
extension StripePaymentService {
    func loadSubscriptions(userId: String, completion: (([Subscription]?, Error?)->Void)?) {
        let params = ["userId": userId]
        
        apiService?.cloudFunction(functionName: "getSubscriptions", method: "POST", params: params) { (result, error) in
            if let error = error {
                completion?(nil, error)
            } else if let result = result as? [String: Any], let dict = result["result"] as? [String: Any] {
                var subscriptions: [Subscription] = []
                for (key, value) in dict {
                    if let dict = value as? [String: Any] {
                        let subscription = Subscription(key: key, dict: dict)
                        subscriptions.append(subscription)
                    }
                }
                completion?(subscriptions, nil)
            } else {
                completion?(nil, nil)
            }
        }
    }
    
    func createSubscription(userId: String, leagueId: String, type: String, completion: (([String: Any]?, Error?)->Void)?) {
        let params = ["userId": userId, "leagueId": "123", "type": "owner"]
        apiService?.cloudFunction(functionName: "createSubscription", method: "POST", params: params) { (result, error) in
            if let error = error {
                completion?(nil, error)
            } else {
                completion?(result as? [String: Any], nil)
            }
        }
    }
}
