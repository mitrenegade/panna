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

class PaymentCell: UITableViewCell {

    var viewModel: PaymentViewModel?

    fileprivate var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        StripeService.shared.status.subscribe(onNext: { [weak self] status in
            self?.viewModel = PaymentViewModel(status: status, privacy: true)
            self?.refreshPayment()
        }).disposed(by: disposeBag)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func refreshPayment() {
        guard let viewModel = viewModel else { return }
        self.textLabel?.text = viewModel.labelTitle
        
        if let paymentMethod = StripeService.shared.paymentContext.value?.selectedPaymentMethod, let card = paymentMethod as? STPCard {
            // always write card to firebase since it's an internal call
            print("updated card")
            PaymentService().savePaymentInfo(card.stripeID, last4: card.last4, label: card.label)
        }
    }
    
    func shouldShowPaymentController() {
        guard let viewModel = viewModel else { return }
        if viewModel.canAddPayment {
            LoggingService.shared.log(event: LoggingEvent.show_payment_controller, info: nil)
            if let context = StripeService.shared.paymentContext.value {
                context.presentPaymentMethodsViewController()
            }
        }
    }
}
