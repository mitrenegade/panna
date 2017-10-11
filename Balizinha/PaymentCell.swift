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
            return "Payment method: \(method.label)"
        }
        else {
            return "Click to add a payment method"
        }
    }
    
    var iconWidth: CGFloat {
        guard let context = paymentContext else { return 40 }
        if context.loading {
            return 40
        }
        else if context.selectedPaymentMethod != nil {
            return 60
        }
        else {
            return 0
        }
    }
    
    var activityIndicatorShouldAnimate: Bool {
        guard let context = paymentContext else { return true }
        if context.loading {
            return true
        }
        return false
    }
    
    var canAddPayment: Bool {
        guard let context = paymentContext else { return false }
        return !context.loading //&& context.selectedPaymentMethod == nil
    }
}

class PaymentCell: UITableViewCell {

    @IBOutlet weak var paymentIcon: UIImageView!
    @IBOutlet weak var paymentLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var constraintIconWidth: NSLayoutConstraint!

    var canAddPayment: Bool = false
    
    let stripeService = StripeService()

    override func awakeFromNib() {
        self.listenFor(NotificationType.PaymentContextChanged, action: #selector(refreshPayment), object: nil)
        
        self.refreshPayment()
    }
    
    func configure() {
        stripeService.loadPayment(host: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func refreshPayment() {
        let viewModel = PaymentCellViewModel(paymentContext: stripeService.paymentContext)
        self.paymentLabel.text = viewModel.labelTitle
        self.constraintIconWidth.constant = viewModel.iconWidth
        if viewModel.activityIndicatorShouldAnimate {
            self.activityIndicator.startAnimating()
        }
        else {
            self.activityIndicator.stopAnimating()
        }
        canAddPayment = viewModel.canAddPayment
        
        if let paymentMethod = stripeService.paymentContext?.selectedPaymentMethod {
            self.paymentIcon.image = paymentMethod.image
            // always write card to firebase since it's an internal call
            stripeService.savePaymentInfo(paymentMethod)
        }
    }
}
