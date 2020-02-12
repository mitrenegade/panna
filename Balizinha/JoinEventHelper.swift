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
    var amountRequired: Double = 0

    init(paymentService: StripePaymentService = Globals.stripePaymentService) {
        self.paymentService = paymentService
    }

    func checkIfPartOfLeague() {
        guard let event = event else { return }
        guard let leagueId = event.leagueId, !leagueId.isEmpty, let player = PlayerService.shared.current.value else {
            shouldChargeForEvent()
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
                            self?.shouldChargeForEvent()
                        }
                        return
                    }

                    let name = event.name ?? "this event"
                    let leagueName = league.name ?? "the league"
                    let alert = UIAlertController(title: "Join league to join event", message: "In order to join \(name), you must be part of the league. Do you want to join \(leagueName) now?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                        // join league
                        LeagueService.shared.join(league: league, completion: { [weak self] (result, error) in
                            DispatchQueue.main.async {
                                if let error = error as NSError? {
                                    self?.delegate?.stopActivityIndicator()
                                    self?.rootViewController?.simpleAlert("Could not join league", defaultMessage: "There was an error joining the league.", error: error)
                                    LoggingService.shared.log(event: .JoinEventClicked, info: [LoggingKey.JoinEventClickedResult.rawValue:LoggingValue.JoinEventClickedResult.joinLeagueError.rawValue, LoggingKey.JoinEventId.rawValue: event.id], error: error)
                                } else {
                                    LoggingService.shared.log(event: .JoinEventClicked, info: [LoggingKey.JoinEventClickedResult.rawValue:LoggingValue.JoinEventClickedResult.joinedLeague.rawValue, LoggingKey.JoinEventId.rawValue: event.id])
                                    self?.notify(.PlayerLeaguesChanged, object: nil, userInfo: nil)
                                    self?.shouldChargeForEvent()
                                }
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
                    self?.shouldChargeForEvent()
                }
            }
        }
    }
    
    func shouldChargeForEvent() {
        guard let event = event else { return }
        guard let current = PlayerService.shared.current.value else {
            let message = "There was an error. Please log in again."
            LoggingService.shared.log(event: .JoinEventClicked, info: [LoggingKey.JoinEventClickedResult.rawValue:LoggingValue.JoinEventClickedResult.invalidPlayer.rawValue, LoggingKey.JoinEventId.rawValue: event.id])
            rootViewController?.simpleAlert("Could not load event", message: message)
            return
        }
        let params: [String: Any] = ["eventId": event.id, "userId": current.id]
        delegate?.startActivityIndicator()
        RenderAPIService().cloudFunction(functionName: "shouldChargeForEvent", method: "POST", params: params) { [weak self] (result, error) in
            DispatchQueue.main.async {
                if let dict = result as? [String: Any] {
                    let paymentRequired = dict["paymentRequired"] as? Bool ?? false
                    if let amount: Double = dict["amount"] as? Double {
                        self?.amountRequired = amount
                    }
                    if paymentRequired {
                        self?.checkIfAlreadyPaid()
                    } else {
                        self?.joinEvent(event, userId: current.id)
                    }
                } else {
                    self?.delegate?.stopActivityIndicator()
                    LoggingService.shared.log(event: .JoinEventClicked, info: [LoggingKey.JoinEventClickedResult.rawValue:LoggingValue.JoinEventClickedResult.chargeForEventError.rawValue, LoggingKey.JoinEventId.rawValue: event.id], error: error as NSError?)
                    self?.rootViewController?.simpleAlert("Could not load event", defaultMessage: "There was an error with this event.", error: error as NSError?)
                }
            }
        }
    }
    
    func checkIfAlreadyPaid() {
        guard let event = event else { return }
        guard let current = PlayerService.shared.current.value else {
            LoggingService.shared.log(event: .JoinEventClicked, info: [LoggingKey.JoinEventClickedResult.rawValue:LoggingValue.JoinEventClickedResult.invalidPlayer.rawValue, LoggingKey.JoinEventId.rawValue: event.id])
            rootViewController?.simpleAlert("Could not make payment", message: "Please update your player profile!")
            return
        }
        guard event.paymentRequired && SettingsService.paymentRequired() else {
            // log that payment was skipped
            LoggingService.shared.log(event: .JoinEventClicked, info: [LoggingKey.JoinEventClickedResult.rawValue:LoggingValue.JoinEventClickedResult.paymentNotRequired.rawValue, LoggingKey.JoinEventId.rawValue: event.id])
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
                LoggingService.shared.log(event: .JoinEventClicked, info: [LoggingKey.JoinEventClickedResult.rawValue:LoggingValue.JoinEventClickedResult.invalidEvent.rawValue])
                rootViewController?.simpleAlert("Invalid event", message: "Could not join event. Please try again.")
                delegate?.stopActivityIndicator()
                return
            }
            doCharge(for: event)
            disposeBag = DisposeBag()
        case .noCustomer, .noPaymentMethod, .needsRefresh:
            delegate?.stopActivityIndicator()
            paymentNeeded(status: status)
            disposeBag = DisposeBag()
        }
    }
    
    func paymentNeeded(status: PaymentStatus) {
        let title: String
        let message: String
        if case .needsRefresh = status {
            title = "Invalid payment method"
            message = "Your current payment method needs to be updated."
            LoggingService.shared.log(event: LoggingEvent.NeedsRefreshPayment, info: ["source": "JoinEventHelper"])
        } else {
            title = "No payment method available"
            message = "This event has a fee. Please add a payment method in your profile."
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Edit Payments", style: .default, handler: { (action) in
            guard let url = URL(string: "panna://account/payments") else { return }
            DeepLinkService.shared.handle(url: url)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            self.delegate?.didCancelPayment()
        }))
        rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    func doCharge(for event: Balizinha.Event) {
        guard let paymentString: String = EventService.amountString(from: NSNumber(value: amountRequired)) else {
            LoggingService.shared.log(event: .JoinEventClicked, info: [LoggingKey.JoinEventClickedResult.rawValue:LoggingValue.JoinEventClickedResult.invalidPaymentAmount.rawValue, LoggingKey.JoinEventId.rawValue: event.id, LoggingKey.JoinEventAmountRequired.rawValue:amountRequired])
            rootViewController?.simpleAlert("Could not calculate payment", message: "Please let us know about this error.")
            delegate?.stopActivityIndicator()
            return
        }
        let alert = UIAlertController(title: "Confirm payment", message: "Press Ok to pay \(paymentString) for this game.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            self.chargeAndWait(event: event, amount: self.amountRequired)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            self.delegate?.didCancelPayment()
        }))
        rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    func chargeAndWait(event: Balizinha.Event, amount: Double) {
        guard let current = PlayerService.shared.current.value else {
            LoggingService.shared.log(event: .JoinEventClicked, info: [LoggingKey.JoinEventClickedResult.rawValue:LoggingValue.JoinEventClickedResult.invalidPlayer.rawValue, LoggingKey.JoinEventId.rawValue: event.id])
            rootViewController?.simpleAlert("Could not make payment", message: "Please update your player profile!")
            delegate?.stopActivityIndicator()
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
                    LoggingService.shared.log(event: .JoinEventClicked, info: [LoggingKey.JoinEventClickedResult.rawValue:LoggingValue.JoinEventClickedResult.paymentError.rawValue, LoggingKey.JoinEventId.rawValue: event.id], error: error)
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
                    LoggingService.shared.log(event: .JoinEventClicked, info: [LoggingKey.JoinEventClickedResult.rawValue:LoggingValue.JoinEventClickedResult.joinEventError.rawValue, LoggingKey.JoinEventId.rawValue: event.id], error: error)
                    self?.rootViewController?.simpleAlert("Could not join game", defaultMessage: "You were unable to join the game.", error: error)
                } else {
                    self?.delegate?.didJoin(event)
                }
            }
        }
        NotificationService.shared.scheduleNotificationForEvent(event)
    }

}
