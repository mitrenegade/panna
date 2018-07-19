//
//  JoinEventHelper.swift
//  Balizinha
//
//  Created by Bobby Ren on 7/19/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Stripe

class JoinEventHelper: NSObject {
    var rootViewController: UIViewController?
    var event: Event?
    
    func checkIfAlreadyPaid(for event: Event) {
        guard event.paymentRequired && SettingsService.paymentRequired() else {
            joinEvent(event)
            return
        }
        
        guard let current = PlayerService.shared.current.value else {
            rootViewController?.simpleAlert("Could not make payment", message: "Please update your player profile!")
            return
        }
        guard event != nil else {
            print("no longer joining event")
            return
        }
//        activityIndicator.startAnimating()
        PaymentService().checkForPayment(for: event.id, by: current.id) { [weak self] (success) in
            if success {
//                self?.activityIndicator.stopAnimating()
                self?.joinEvent(event)
            }
            else {
                self?.checkStripe()
            }
        }
    }
    
    func checkStripe() {
        listenFor(NotificationType.PaymentContextChanged, action: #selector(refreshStripeStatus), object: nil)
        refreshStripeStatus()
    }
    
    @objc func refreshStripeStatus() {
        guard let paymentContext = StripeService.shared.paymentContext.value else { return }
        if paymentContext.loading {
//            activityIndicator.startAnimating()
        }
        else {
//            activityIndicator.stopAnimating()
            if let paymentMethod = paymentContext.selectedPaymentMethod {
                guard let event = event else {
                    rootViewController?.simpleAlert("Invalid event", message: "Could not join event. Please try again.")
                    return
                }
                shouldCharge(for: event, payment: paymentMethod)
            }
            else {
                paymentNeeded()
            }
            stopListeningFor(NotificationType.PaymentContextChanged)
        }
    }
    
    func paymentNeeded() {
        let alert = UIAlertController(title: "No payment method available", message: "This event has a fee. Please add a payment method in your profile.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Edit Payments", style: .default, handler: { (action) in
            guard let url = URL(string: "balizinha://account/payments") else { return }
            DeepLinkService.shared.handle(url: url)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
        }))
        rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func calculateAmountForEvent(event: Event, completion:@escaping ((Double)->Void)) {
        let amount = event.amount?.doubleValue ?? 0
        if let promotionId = PlayerService.shared.current.value?.promotionId {
            PromotionService.shared.withId(id: promotionId, completion: { (promotion, error) in
                if let promotion = promotion, let discount = promotion.discountFactor {
                    print("Event cost with discount of \(discount) = \(amount * discount)")
                    completion(amount * discount)
                }
                else {
                    print("Event cost either has no promotion or no discount. Error: \(error)")
                    completion(amount)
                }
            })
        }
        else {
            print("Event cost has no promotion")
            completion(amount)
        }
    }
    
    func shouldCharge(for event: Event, payment: STPPaymentMethod) {
        calculateAmountForEvent(event: event) {[weak self] (amount) in
            guard let paymentString: String = EventService.amountString(from: NSNumber(value: amount)) else {
                self?.rootViewController?.simpleAlert("Could not calculate payment", message: "Please let us know about this error.")
                return
            }
            let alert = UIAlertController(title: "Confirm payment", message: "Press Ok to pay \(paymentString) for this game.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { [weak self] (action) in
                self?.chargeAndWait(event: event, amount: amount)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            }))
            self?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    func chargeAndWait(event: Event, amount: Double) {
        guard let current = PlayerService.shared.current.value else {
            rootViewController?.simpleAlert("Could not make payment", message: "Please update your player profile!")
            return
        }
//        activityIndicator.startAnimating()
        
        StripeService.shared.createCharge(for: event, amount: amount, player: current, completion: {[weak self] (success, error) in
//            self?.activityIndicator.stopAnimating()
            if success {
                self?.joinEvent(event)
                self?.event = nil
            }
            else if let error = error as? NSError {
                var errorMessage = ""
                if let errorString = error.userInfo["error"] as? String {
                    errorMessage = "Error: \(errorString)"
                }
                self?.rootViewController?.simpleAlert("Could not join game", message: "There was an issue making a payment. \(errorMessage)")
            }
        })
    }
    
    fileprivate func joinEvent(_ event: Event) {
        //add notification in case user doesn't return to MyEvents
        EventService.shared.joinEvent(event)
        if #available(iOS 10.0, *) {
            NotificationService.shared.scheduleNotificationForEvent(event)
            
            if SettingsService.donation() {
                NotificationService.shared.scheduleNotificationForDonation(event)
            }
        }
        
        if UserDefaults.standard.bool(forKey: UserSettings.DisplayedJoinEventMessage.rawValue) == false {
            rootViewController?.simpleAlert("You've joined a game", message: "You can go to your Calendar to see upcoming events.")
            UserDefaults.standard.set(true, forKey: UserSettings.DisplayedJoinEventMessage.rawValue)
            UserDefaults.standard.synchronize()
        }
    }

}
