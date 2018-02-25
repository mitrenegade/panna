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

class StripeService: NSObject {
    // payment method
    var paymentContext: STPPaymentContext?
    var hostController: UIViewController?
    
    var customerId: String?

    var completionHandler: STPJSONResponseCompletionBlock?
    
    var baseURL: URL? {
        let urlSuffix = TESTING ? "-dev" : "-c9cd7"
        return URL(string: "https://us-central1-balizinha\(urlSuffix).cloudfunctions.net/")
    }

    func loadPayment(host: UIViewController?) {
        guard let player = PlayerService.shared.current else {
            return
        }
        
        let ref = firRef.child("stripe_customers").child(player.id).child("customer_id")
        ref.observe(.value, with: { (snapshot) in
            guard snapshot.exists(), let customerId = snapshot.value as? String else {
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
        guard !PlayerService.isAnonymous else { return }
        let ref = firRef.child("stripe_customers").child(player.id).child("customer_id")
        ref.observe(.value, with: { (snapshot) in
            guard snapshot.exists(), let customerId = snapshot.value as? String else {
                // old player does not have a stripe customer, must create one
                self.createCustomer()
                return
            }
            // otherwise stripe customer exists and all is well
            print("stripe_customer for player \(player.id) exists: \(customerId)")
        })
    }
    
    func createCustomer() {
        guard let url = self.baseURL?.appendingPathComponent("createStripeCustomerForLegacyUser_v0_2") else { return }
        guard let email = PlayerService.shared.current?.email else { return }
        guard let id = PlayerService.shared.current?.id else { return }
        let params: [String: Any] = ["email": email, "id": id]
        let method = "POST"
        FirebaseAPIService.shared.cloudFunction(url: url.absoluteString, method: method, params: params) { (result, error) in
            
        }
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
            LoggingService.shared.log(event: LoggingEvent.FeatureFlagError, info: ["feature": "paymentRequired", "function": "createCharge"])
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
            guard snapshot.exists() else {
                // this can happen if we've created a charge object and deleted it. observer returns on the reference being deleted. shouldn'd delete the object, but in this situation just ignore.
                return
            }
            guard let info = snapshot.value as? [String: AnyObject] else {
                completion?(false,  NSError(domain: "stripe", code: 0, userInfo: ["error": "Could not save charge for eventId \(event.id) for player \(player.id)"]))
                return
            }
            if let status = info["status"] as? String, status == "succeeded" {
                print("status \(status)")
                completion?(true, nil)
            }
            else if let error = info["error"] as? String {
                completion?(false, NSError(domain: "stripe", code: 0, userInfo: ["error": error]))
            }
        }
    }
    
    func createSubscription(isTrial: Bool, completion: ((_ success: Bool,_ error: Error?)->())?) {
        guard let organizer = OrganizerService.shared.current else {
            completion?(false, NSError(domain: "balizinha", code: 0, userInfo: ["error": "Could not create subscription: no organizer"]))
            return
        }
        guard SettingsService.paymentRequired() || SettingsService.donation() else {
            // this error prevents rampant charges, but does present an error message to the user
            LoggingService.shared.log(event: LoggingEvent.FeatureFlagError, info: ["feature": "paymentRequired", "function": "createCharge"])
            completion?(false, NSError(domain: "balizinha", code: 0, userInfo: ["error": "Payment not allowed for Balizinha"]))
            return
        }
        let ref = firRef.child("charges/organizers").child(organizer.id).childByAutoId()
        print("Creating charge for organizer \(organizer.id)")
        
        // todo: set trial length here and send it into the cloud function?
        let params = ["subscription": true, "isTrial": isTrial]
        
        ref.updateChildValues(params)
        ref.observe(.value) { (snapshot: DataSnapshot) in
            guard snapshot.exists(), let info = snapshot.value as? [String: AnyObject] else {
                completion?(false,  NSError(domain: "stripe", code: 0, userInfo: ["error": "Could not save subscription for organizer \(organizer.id)"]))
                return
            }
            if let status = info["status"] as? String, status == "active" || status == "trialing"{
                print("status \(status)")
                completion?(true, nil)
            }
            else if let error = info["error"] as? String {
                let code: Int
                if error == "This customer has no attached payment source" {
                    code = 1001
                } else {
                    code = 1000
                }
                var userInfo: [String: Any] = ["error": error]
                if let deadline = info["deadline"] as? Double {
                    userInfo["deadline"] = deadline
                }
                completion?(false, NSError(domain: "stripe", code: code, userInfo: userInfo))
            }
        }
    }
}

// MARK: - STPPaymentContextDelegate
extension StripeService: STPPaymentContextDelegate {
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        print("didChange. loading \(paymentContext.loading)")

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
extension StripeService: STPEphemeralKeyProvider {
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        guard let url = self.baseURL?.appendingPathComponent("ephemeralKeys") else { return }
        guard let customerId = self.customerId else { return }
        let params: [String: Any] = ["api_version": apiVersion, "customer_id": customerId]
        let method = "POST"
        FirebaseAPIService.shared.cloudFunction(url: url.absoluteString, method: method, params: params) { (result, error) in
            completion(result as? [AnyHashable: Any], error)
        }
    }
}
