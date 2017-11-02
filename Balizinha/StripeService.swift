//
//  StripeService.swift
//  Balizinha
//
//  Created by Bobby Ren on 9/21/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Stripe
import Firebase

fileprivate var singleton: StripeService?

class StripeService: NSObject, STPEphemeralKeyProvider {
//    static var shared: StripeService {
//        if singleton == nil {
//            singleton = StripeService()
//        }
//        
//        return singleton!
//        
//    }
    
    // payment method
    var paymentContext: STPPaymentContext?
    var hostController: UIViewController?
    
    // variables for creating customer key
    let opQueue = OperationQueue()
    var urlSession: URLSession?
    var dataTask: URLSessionTask?
    var data: Data?
    var customerId: String?

    var completionHandler: STPJSONResponseCompletionBlock?
    
    var baseURL: URL? {
        let urlSuffix = TESTING ? "-dev" : "-c9cd7"
        return URL(string: "https://us-central1-balizinha\(urlSuffix).cloudfunctions.net/")
    }
    
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        guard let url = self.baseURL?.appendingPathComponent("ephemeralKeys") else { return }
        
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: self.opQueue)
        
        let params = ["api_version": apiVersion, "customer_id": self.customerId]
        var request = URLRequest(url:url)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")

        try! request.httpBody = JSONSerialization.data(withJSONObject: params, options: [])
        
        self.completionHandler = completion
        
        let task = urlSession?.dataTask(with: request)
        task?.resume()
    }
    
    func loadPayment(host: UIViewController?) {
        guard let player = PlayerService.shared.current else {
            return
        }
        
        let ref = firRef.child("stripe_customers").child(player.id).child("customer_id")
        ref.observe(.value, with: { (snapshot) in
            guard let customerId = snapshot.value as? String else {
                // old player does not have a stripe customer, must create one
                print("uh oh")
                if let player = PlayerService.shared.current {
                    self.checkForStripeCustomer(player)
                }
                return
            }
            self.customerId = customerId
            let customerContext = STPCustomerContext(keyProvider: self)
            self.paymentContext = STPPaymentContext(customerContext: customerContext)
            self.paymentContext?.delegate = self
            if let host = host {
                self.paymentContext?.hostViewController = host
            }
        })
    }
    
    // for legacy users
    func checkForStripeCustomer(_ player: Player) {
        let ref = firRef.child("stripe_customers").child(player.id).child("customer_id")
        ref.observe(.value, with: { (snapshot) in
            guard let customerId = snapshot.value as? String else {
                // old player does not have a stripe customer, must create one
                self.createCustomer()
                return
            }
            // otherwise stripe customer exists and all is well
            print("stripe_customer for player \(player.id) exists: \(customerId)")
        })
    }
    
    func createCustomer() {
        guard let url = self.baseURL?.appendingPathComponent("createStripeCustomerForLegacyUser") else { return }
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: self.opQueue)
        
        let params = ["email": PlayerService.shared.current?.email, "id": PlayerService.shared.current?.id]
        var request = URLRequest(url:url)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        
        try! request.httpBody = JSONSerialization.data(withJSONObject: params, options: [])
        let task = urlSession?.dataTask(with: request)
        task?.resume()
    }
    
    func savePaymentInfo(_ paymentMethod: STPPaymentMethod) {
        // calls this function after a payment source has been created
        guard let player = PlayerService.shared.current, let card = paymentMethod as? STPCard else { return }
        let ref = firRef.child("stripe_customers").child(player.id)
        let params: [String: Any] = ["source": card.stripeID, "last4":card.last4, "label": card.label]
        ref.updateChildValues(params)
    }
    
    func createCharge(for event: Event, amount: Double, player: Player, isDonation: Bool = false, completion: ((_ success: Bool,_ error: Error?)->())?) {
        guard amount > 0 else {
            print("Invalid amount on event")
            completion?(false, NSError(domain: "balizinha", code: 0, userInfo: ["error": "Invalid amount on event", "eventId": event.id]))
            return
        }
        guard SettingsService.paymentRequired() || SettingsService.donation() else {
            // this error prevents rampant charges, but does present an error message to the user
            LoggingService.shared.log(event: "FeatureFlagError", info: ["feature": "paymentRequired", "function": "createCharge"])
            completion?(false, NSError(domain: "balizinha", code: 0, userInfo: ["error": "Payment not allowed for Balizinha"]))
            return
        }
        let ref = firRef.child("charges/events").child(event.id).childByAutoId()
        let cents = ceil(amount * 100.0)
        var params:[AnyHashable: Any] = ["amount": cents, "player_id": player.id]
        if isDonation {
            params["isDonation"] = true
        }
        print("Creating charge for event \(event.id) for \(cents) cents")
        ref.updateChildValues(params)
        ref.observe(.value) { (snapshot: DataSnapshot) in
            if let info = snapshot.value as? [String: AnyObject] {
                if let status = info["status"] as? String, status == "succeeded" {
                    print("status \(status)")
                    completion?(true, nil)
                }
                else if let error = info["error"] as? String {
                    completion?(false, NSError(domain: "stripe", code: 0, userInfo: ["error": error]))
                }
//                completion?(false, NSError(domain: "stripe", code: 0, userInfo: ["error": "Unknown status"]))
            }
        }
    }
    
    func createSubscription(completion: ((_ success: Bool,_ error: Error?)->())?) {
        guard let organizer = OrganizerService.shared.current else {
            completion?(false, NSError(domain: "balizinha", code: 0, userInfo: ["error": "Could not create subscription: no organizer"]))
            return
        }
        guard SettingsService.paymentRequired() || SettingsService.donation() else {
            // this error prevents rampant charges, but does present an error message to the user
            LoggingService.shared.log(event: "FeatureFlagError", info: ["feature": "paymentRequired", "function": "createCharge"])
            completion?(false, NSError(domain: "balizinha", code: 0, userInfo: ["error": "Payment not allowed for Balizinha"]))
            return
        }
        let ref = firRef.child("charges/organizers").child(organizer.id).childByAutoId()
        print("Creating charge for organizer \(organizer.id)")
        
        // todo: set trial length here and send it into the cloud function?
        let params = ["subscription": true]
        
        ref.updateChildValues(params)
        ref.observe(.value) { (snapshot: DataSnapshot) in
            if let info = snapshot.value as? [String: AnyObject] {
                if let status = info["status"] as? String, status == "active" {
                    print("status \(status)")
                    completion?(true, nil)
                }
                else if let error = info["error"] as? String {
                    completion?(false, NSError(domain: "stripe", code: 0, userInfo: ["error": error]))
                }
                else {
//                    completion?(false, NSError(domain: "stripe", code: 0, userInfo: ["error": "Unknown status"]))
                }
            }
        }
    }

}

// MARK: - STPPaymentContextDelegate
extension StripeService: STPPaymentContextDelegate {
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        print("didChange")

        self.notify(NotificationType.PaymentContextChanged, object: nil, userInfo: nil)
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext,
                        didCreatePaymentResult paymentResult: STPPaymentResult,
                        completion: @escaping STPErrorBlock) {
        print("didCreatePayment")
    }
    
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        print("didFinish")
        switch status {
        case .error: break
        //            self.showError(error)
        case .success: break
        //            self.showReceipt()
        case .userCancellation:
            return // Do nothing
        }
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext,
                        didFailToLoadWithError error: Error) {
        print("didFailToLoad error \(error)")
        // Show the error to your user, etc.
    }
    
    
}

// MARK: - Customer Key
extension StripeService: URLSessionDelegate, URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("data received")
        if let data = self.data {
            self.data?.append(data)
        }
        else {
            self.data = data
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("completed")
        defer {
            self.data = nil
            self.completionHandler = nil
        }
        
        if let usableData = self.data {
            do {
                let json = try JSONSerialization.jsonObject(with: usableData, options: [])
                print("urlSession completed with json \(json)")
                completionHandler?(json as? [String: AnyObject], nil)
            } catch let error {
                print("error \(error)")
                completionHandler?(nil, error)
            }
        }
        else if let error = error {
            completionHandler?(nil, error)
        }
        else {
            print("here")
        }
    }

    //    func test() {
    //        let urlString = "https://us-central1-balizinha-dev.cloudfunctions.net/testFunction"
    //        guard let requestUrl = URL(string:urlString) else { return }
    //        let request = URLRequest(url:requestUrl)
    //        let task = URLSession.shared.dataTask(with: request) {
    //            (data, response, error) in
    //            if let usableData = data {
    //                do {
    //                    let json = try JSONSerialization.jsonObject(with: usableData, options: [])
    //                    print("json \(json)") //JSONSerialization
    //                } catch let error as Error {
    //                    print("error \(error)")
    //                }
    //            }
    //            else if let error = error {
    //                print("error \(error)")
    //            }
    //        }
    //        task.resume()
    //    }

}

