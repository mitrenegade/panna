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
    weak var paymentService: StripePaymentService!
    weak var hostController: UIViewController? {
        didSet {
            paymentService.loadPayment(hostController: hostController)
        }
    }

    fileprivate var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        paymentService = Globals.stripePaymentService
        paymentService.statusObserver.subscribe(onNext: { [weak self] status in
            self?.viewModel = PaymentViewModel(status: status, privacy: true)
            print("BOBBYTEST status \(status)")
            self?.refreshPayment(status)
        }).disposed(by: disposeBag)
    }
    
    func refreshPayment(_ status: PaymentStatus) {
        guard let viewModel = viewModel else { return }
        guard let player = PlayerService.shared.current.value else { return }
        textLabel?.text = viewModel.labelTitle
        
        switch status {
        case .ready(let paymentSource):
            // always write card to firebase since it's an internal call
            print("Working payment source \(paymentSource)")
            
            // BOBBY TODO: where to savePaymentInfo?
//            paymentService.savePaymentInfo(userId: player.id, source: card.stripeID, last4: card.last4, label: card.label)

        default:
            break
        }
    }
    
    func shouldShowPaymentController() {
        guard let viewModel = viewModel else { return }
        if viewModel.canAddPayment {
            LoggingService.shared.log(event: LoggingEvent.show_payment_controller, info: nil)
            paymentService.shouldShowPaymentController()
        } else if viewModel.needsValidateCustomer {
            LoggingService.shared.log(event: LoggingEvent.NeedsValidateCustomer, info: nil)
            if let player = PlayerService.shared.current.value, let email = player.email {
                paymentService.createCustomer(userId: player.id, email: email) { [weak self] (customerId, error) in
                    print("CustomerId \(customerId) error \(error)")
                }
            }
        }
    }
}
