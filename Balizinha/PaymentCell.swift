//
//  PaymentCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 10/10/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase
import Stripe

class PaymentCell: UITableViewCell {

    let stripeService = StripeService()

    override func awakeFromNib() {
        self.listenFor(NotificationType.PaymentContextChanged, action: #selector(refreshPayment), object: nil)
        
        self.refreshPayment()
    }
    
    func configure(host: UIViewController?) {
        stripeService.loadPayment(host: host)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func refreshPayment() {
        let viewModel = PaymentViewModel(paymentContext: stripeService.paymentContext, privacy: true)
        self.textLabel?.text = viewModel.labelTitle
        
        if let paymentMethod = stripeService.paymentContext?.selectedPaymentMethod {
            // always write card to firebase since it's an internal call
            print("updated card")
            stripeService.savePaymentInfo(paymentMethod)
        }
    }
    
    func shouldShowPaymentController() {
        let viewModel = PaymentViewModel(paymentContext: stripeService.paymentContext)
        if viewModel.canAddPayment {
            LoggingService.shared.log(event: LoggingEvent.show_payment_controller, info: nil)
            stripeService.paymentContext?.presentPaymentMethodsViewController()
        }
    }
}
