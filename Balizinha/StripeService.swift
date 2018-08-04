//
//  StripeService.swift
//  Balizinha
//
//  Created by Bobby Ren on 9/21/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Stripe
import FirebaseCommunity
import RxSwift

enum PaymentStatus {
    case none // no customer_id exists
    case loading // customer_id exists, loading payment
    case ready(paymentMethod: STPPaymentMethod?)
}

func ==(lhs: PaymentStatus, rhs: PaymentStatus) -> Bool {
    switch (lhs, rhs) {
    case (.none, .none):
        return true
    case (.loading, .loading):
        return true
    case (.ready(let p1), .ready(let p2)):
        if p1 == nil && p2 == nil {
            return true
        }
        if p1 != nil && p2 != nil {
            return true
        }
        return false
    default:
        return false
    }
}

class StripeService: NSObject {
    static let shared = StripeService()
    
    // payment method
    var paymentContext: Variable<STPPaymentContext?> = Variable(nil)
    var customerId: Variable<String?> = Variable(nil)
    fileprivate var paymentContextLoading: Variable<Bool> = Variable(false) // when paymentContext loading state changes, we don't get a reactive notification
    let status: Observable<PaymentStatus>
    
    weak var hostController: UIViewController? {
        didSet {
            self.paymentContext.value?.hostViewController = hostController
        }
    }
    
    fileprivate var disposeBag: DisposeBag
    
    override init() {
        // status: no customer_id = none
        // status: customer_id, no paymentContext = loading, should trigger creating payment context
        // status: customer_id, paymentContext.loading = loading
        // status: customer_id, !paymentContext.loading, paymentMethod is nil = Add a payment (none)
        // status: customer_id, !paymentContext.loading, paymentMethod exists = View payments (ready)
        disposeBag = DisposeBag()
        print("StripeService: starting observing to update status")
        self.status = Observable.combineLatest(paymentContext.asObservable(), customerId.asObservable(), paymentContextLoading.asObservable()) {context, customerId, loading in
            guard let customerId = customerId else {
                return .none
            }
            guard let context = context else {
                return .loading
            }
            if context.loading { // use actual loading value; paymentContextLoading is only used as a trigger
                // customer exists, context exists, loading payment method
                print("StripeService: status update: \(PaymentStatus.loading)")
                return .loading
            }
            else if let paymentMethod = context.selectedPaymentMethod {
                // customer exists, context exists, payment exists
                print("StripeService: status update: \(PaymentStatus.ready)")
                return .ready(paymentMethod: paymentMethod)
            } else {
                // customer exists, context exists, no payment method
                print("StripeService: status update: \(PaymentStatus.none)")
                return .none
            }
        }

        // TODO: when customer ID is set, create context
        super.init()

        startPlayerListener()
    }
    
    fileprivate func startPlayerListener() {
        // listen for player object in order to get customer id
        // TODO: make sure playerService restarts its observing on logout/login
        PlayerService.shared.current.asObservable().subscribe(onNext: {player in
            guard let player = player else { return }
            let userId = player.id
            let ref = firRef.child("stripe_customers").child(player.id).child("customer_id")
            ref.observe(.value, with: { (snapshot) in
                guard snapshot.exists(), let customerId = snapshot.value as? String else {
                    self.paymentContext.value = nil
                    self.validateStripeCustomer(for: player)
                    return
                }
                
                print("StripeService: updated customer id \(customerId) for player \(userId)")
                self.customerId.value = customerId
                self.loadPayment(for: player)
            })
        }).disposed(by: disposeBag)
    }
    
    class func resetOnLogout() {
        print("StripeService: resetting on logout")
        StripeService.shared.disposeBag = DisposeBag()
        StripeService.shared.customerId.value = nil
        StripeService.shared.paymentContextLoading.value = false
        StripeService.shared.paymentContext.value = nil
        StripeService.shared.hostController = nil
        
        StripeService.shared.startPlayerListener()
    }

    func loadPayment(for player: Player) {
        guard let customerId = self.customerId.value else { return }
        guard self.paymentContext.value == nil else { return }
        
        print("StripeService: loadPayment for customer \(customerId)")
        let customerContext = STPCustomerContext(keyProvider: self)
        let paymentContext = STPPaymentContext(customerContext: customerContext)
        paymentContext.delegate = self
        if let hostController = self.hostController {
            paymentContext.hostViewController = hostController
        }
        self.paymentContext.value = paymentContext
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
        let id = FirebaseAPIService.uniqueId()
        let ref = firRef.child("charges/events").child(event.id).child(id)
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
        let id = FirebaseAPIService.uniqueId()
        let ref = firRef.child("charges/organizers").child(organizer.id).child(id)
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
    
    func validateStripeCustomer(for player: Player) {
        // kicks off a process to create a new customer, then create a new payment context
        var userEmail: String?
        if player.email != nil {
            userEmail = player.email
        } else if AuthService.currentUser?.email != nil {
            userEmail = AuthService.currentUser?.email
            player.email = userEmail
        }
        guard let email = userEmail else {
            // todo: handle error
            return
        }
        print("StripeService: calling validateStripeCustomer")
        FirebaseAPIService().cloudFunction(functionName: "validateStripeCustomer", method: "POST", params: ["userId": player.id, "email": email], completion: { [weak self] (result, error) in
            // TODO: parse customer id and store it
            print("StripeService: validateStripeCustomer result: \(result) error: \(error)")
            if let json = result as? [String: Any], let customer_id = json["customer_id"] as? String {
                self?.customerId.value = customer_id
            }
        })
    }
}

// MARK: - STPPaymentContextDelegate
extension StripeService: STPPaymentContextDelegate {
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        print("StripeService: paymentContextDidChange. loading \(paymentContext.loading), selected payment \(paymentContext.selectedPaymentMethod)")

        paymentContextLoading.value = paymentContext.loading
        self.notify(NotificationType.PaymentContextChanged, object: nil, userInfo: nil)
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext,
                        didCreatePaymentResult paymentResult: STPPaymentResult,
                        completion: @escaping STPErrorBlock) {
        print("StripeService: paymentContext didCreatePayment with result \(paymentResult)")
    }
    
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        print("StripeService: paymentContext didFinish")
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
        print("StripeService: paymentContext didFailToLoad error \(error)")
        // Show the error to your user, etc.
    }
    
    
}

// MARK: - Customer Key
extension StripeService: STPEphemeralKeyProvider {
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        guard let customerId = self.customerId.value else { return }
        let params: [String: Any] = ["api_version": apiVersion, "customer_id": customerId]
        let method = "POST"
        FirebaseAPIService().cloudFunction(functionName: "ephemeralKeys", method: method, params: params) { (result, error) in
            completion(result as? [AnyHashable: Any], error)
        }
    }
}
