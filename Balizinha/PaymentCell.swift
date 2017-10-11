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

class PaymentCellViewModel: NSObject {
    let paymentContext: STPPaymentContext?
    init(paymentContext: STPPaymentContext?) {
        self.paymentContext = paymentContext
    }
    
    var labelTitle: String {
        if paymentContext?.loading == true || paymentContext == nil {
            return "Loading your payment methods"
        }
        else if let method = paymentContext?.selectedPaymentMethod {
            return "Click to edit payment methods"
        }
        else {
            return "No payment methods. Click to add one"
        }
    }
    
    var canAddPayment: Bool {
        guard let context = paymentContext else { return false }
        return !context.loading
    }
}

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
        let viewModel = PaymentCellViewModel(paymentContext: stripeService.paymentContext)
        self.textLabel?.text = viewModel.labelTitle
        
        if let paymentMethod = stripeService.paymentContext?.selectedPaymentMethod {
            // always write card to firebase since it's an internal call
            print("updated card")
            stripeService.savePaymentInfo(paymentMethod)
        }
    }
    
    func shouldShowPaymentController() {
        let viewModel = PaymentCellViewModel(paymentContext: stripeService.paymentContext)
        if viewModel.canAddPayment {
            stripeService.paymentContext?.presentPaymentMethodsViewController()
        }
    }
}
