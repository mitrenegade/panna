//
//  PaymentCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 10/10/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Stripe
import RxSwift
import Balizinha
import RenderPay
import RenderCloud

class PaymentCell: UITableViewCell {

    var viewModel: PaymentViewModel?
    let paymentService = StripePaymentService(apiService: FirebaseAPIService())
    var hostController: UIViewController? {
        didSet {
            paymentService.hostController = hostController
        }
    }

    fileprivate var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        paymentService.statusObserver.subscribe(onNext: { [weak self] status in
            self?.viewModel = PaymentViewModel(status: status, privacy: true)
            self?.refreshPayment(status)
        }).disposed(by: disposeBag)
        refreshPayment(.loading)
        
        PlayerService.shared.current.asObservable().filterNil().take(1).subscribe(onNext: { [weak self] (player) in
            let userId = player.id
            self?.paymentService.startListeningForAccount(userId: userId)
            self?.paymentService.hostController = self?.hostController
        }).disposed(by: disposeBag)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func refreshPayment(_ status: PaymentStatus) {
        guard let viewModel = viewModel else { return }
        guard let player = PlayerService.shared.current.value else { return }
        self.textLabel?.text = viewModel.labelTitle
        
        switch status {
        case .ready(let paymentMethod):
            if let paymentMethod = paymentMethod, let card = paymentMethod as? STPCard {
                // always write card to firebase since it's an internal call
                print("updated card")
                paymentService.savePaymentInfo(userId: player.id, source: card.stripeID, last4: card.last4, label: card.label)
            } else if let paymentMethod = paymentMethod, let source = paymentMethod as? STPSource {
                // always write card to firebase since it's an internal call
                print("updated source")
                paymentService.savePaymentInfo(userId: player.id, source: source.stripeID, last4: source.cardDetails?.last4 ?? "", label: source.label)
            }

        default:
            break
        }
    }
    
    func shouldShowPaymentController() {
        guard let viewModel = viewModel else { return }
        if viewModel.canAddPayment {
            LoggingService.shared.log(event: LoggingEvent.show_payment_controller, info: nil)
            paymentService.shouldShowPaymentController()
        }
    }
}
