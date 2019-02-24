//
//  JoinEventHelper.swift
//  Balizinha
//
//  Created by Bobby Ren on 7/19/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Stripe
import Balizinha
import RenderPay
import RenderCloud
import RxSwift
import RxCocoa

protocol JoinEventDelegate: class {
    func startActivityIndicator()
    func stopActivityIndicator()
    func didCancelPayment()
    func didJoin(_ event: Balizinha.Event?)
}

class JoinEventHelper: NSObject {
    var rootViewController: UIViewController?
    var event: Balizinha.Event?
    weak var delegate: JoinEventDelegate?
    let paymentService: StripePaymentService
    private var disposeBag: DisposeBag = DisposeBag()

    init(paymentService: StripePaymentService = Globals.stripePaymentService) {
        self.paymentService = paymentService
    }

    func checkIfPartOfLeague() {
        guard let event = event else { return }
        guard let leagueId = event.league, !leagueId.isEmpty, let player = PlayerService.shared.current.value else {
            checkIfAlreadyPaid()
            return
        }
            
        delegate?.startActivityIndicator()
        LeagueService.shared.leagueMemberships(for: player) { [weak self] (roster) in
            let membership: Membership.Status? = roster?.filter() { $0.key == leagueId }.first?.value
            if membership == nil || membership == Membership.Status.none {
                // prompt to join league
                LeagueService.shared.withId(id: leagueId, completion: { [weak self] (league) in
                    guard let league = league else {
                        DispatchQueue.main.async {
                            self?.checkIfAlreadyPaid()
                        }
                        return
                    }

                    let name = event.name ?? "this event"
                    let leagueName = league.name ?? "the league"
                    let alert = UIAlertController(title: "Join league to join event", message: "In order to join \(name), you must be part of the league. Do you want to join \(leagueName) now?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                        // join league
                        LeagueService.shared.join(league: league, completion: { [weak self] (result, error) in
                            if let error = error as NSError? {
                                self?.rootViewController?.simpleAlert("Could not join league", defaultMessage: "There was an error joining the league.", error: error)
                            } else {
                                self?.notify(.PlayerLeaguesChanged, object: nil, userInfo: nil)
                                self?.checkIfAlreadyPaid()
                            }
                        })
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                        self?.delegate?.stopActivityIndicator()
                    }))
                    DispatchQueue.main.async {
                        self?.rootViewController?.present(alert, animated: true, completion: nil)
                    }
                })
            } else {
                DispatchQueue.main.async {
                    self?.checkIfAlreadyPaid()
                }
            }
        }
    }
    
    func checkIfAlreadyPaid() {
        guard let event = event else { return }
        guard let current = PlayerService.shared.current.value else {
            rootViewController?.simpleAlert("Could not make payment", message: "Please update your player profile!")
            return
        }
        guard event.paymentRequired && SettingsService.paymentRequired() else {
            joinEvent(event, userId: current.id)
            return
        }
        delegate?.startActivityIndicator()
        paymentService.startListeningForAccount(userId: current.id)
        paymentService.checkForPayment(for: event.id, by: current.id) { [weak self] (success) in
            self?.delegate?.stopActivityIndicator()
            if success {
                self?.joinEvent(event, userId: current.id)
            }
            else {
                self?.checkStripe()
            }
        }
    }
    
    func checkStripe() {
        paymentService.statusObserver.subscribe(onNext: { [weak self] (status) in
            self?.refreshStripeStatus(status)
        }).disposed(by: disposeBag)
        paymentService.loadPayment(hostController: rootViewController)
    }
    
    func refreshStripeStatus(_ status: PaymentStatus) {
        switch status {
        case .loading:
            delegate?.startActivityIndicator()
        case .ready:
            delegate?.stopActivityIndicator()
            guard let event = event else {
                rootViewController?.simpleAlert("Invalid event", message: "Could not join event. Please try again.")
                return
            }
            shouldCharge(for: event)
            disposeBag = DisposeBag()
        default:
            delegate?.stopActivityIndicator()
            paymentNeeded()
            disposeBag = DisposeBag()
        }
    }
    
    func paymentNeeded() {
        let alert = UIAlertController(title: "No payment method available", message: "This event has a fee. Please add a payment method in your profile.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Edit Payments", style: .default, handler: { (action) in
            guard let url = URL(string: "panna://account/payments") else { return }
            DeepLinkService.shared.handle(url: url)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            self.delegate?.didCancelPayment()
        }))
        rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func calculateAmountForEvent(event: Balizinha.Event, completion:@escaping ((Double)->Void)) {
        let amount = event.amount?.doubleValue ?? 0
        if let promotionId = PlayerService.shared.current.value?.promotionId {
            delegate?.startActivityIndicator()
            PromotionService.shared.withId(id: promotionId, completion: { [weak self] (promotion, error) in
                self?.delegate?.stopActivityIndicator()
                if let promotion = promotion, let discount = promotion.discountFactor {
                    print("Balizinha.Event cost with discount of \(discount) = \(amount * discount)")
                    completion(amount * discount)
                }
                else {
                    print("Balizinha.Event cost either has no promotion or no discount. Error: \(String(describing: error))")
                    completion(amount)
                }
            })
        }
        else {
            print("Balizinha.Event cost has no promotion")
            completion(amount)
        }
    }
    
    func shouldCharge(for event: Balizinha.Event) {
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
                self?.delegate?.didCancelPayment()
            }))
            self?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    func chargeAndWait(event: Balizinha.Event, amount: Double) {
        guard let current = PlayerService.shared.current.value else {
            rootViewController?.simpleAlert("Could not make payment", message: "Please update your player profile!")
            return
        }
        delegate?.startActivityIndicator()
        
        paymentService.makePayment(userId: current.id, eventId: event.id) { [weak self] (result, error) in
            DispatchQueue.main.async {
                self?.delegate?.stopActivityIndicator()
                if let error = error as NSError? {
                    var errorMessage = ""
                    if let errorString = error.userInfo["error"] as? String {
                        errorMessage = "Error: \(errorString)"
                    }
                    self?.rootViewController?.simpleAlert("Could not join game", message: "There was an issue making a payment. \(errorMessage)")
                } else {
                    self?.joinEvent(event, userId: current.id)
                    self?.event = nil
                }
            }
        }
    }
    
    func joinEvent(_ event: Balizinha.Event, userId: String?) {
        //add notification in case user doesn't return to MyEvents
        delegate?.startActivityIndicator()
        guard let userId = userId else { return }
        EventService.shared.joinEvent(event, userId: userId) { [weak self] (error) in
            DispatchQueue.main.async {
                self?.delegate?.stopActivityIndicator()
                if let error = error as NSError? {
                    self?.rootViewController?.simpleAlert("Could not join game", defaultMessage: "You were unable to join the game.", error: error)
                } else {
                    self?.delegate?.didJoin(event)
                }
            }
        }
        NotificationService.shared.scheduleNotificationForEvent(event)
    }

}
