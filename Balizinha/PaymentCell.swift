//
//  PaymentCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 10/10/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

class PaymentCell: UITableViewCell {

    @IBOutlet weak var paymentIcon: UIImageView!
    @IBOutlet weak var paymentLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var constraintIconWidth: NSLayoutConstraint!

    var canAddPayment: Bool = false
    
    let stripeService = StripeService()

    override func awakeFromNib() {
        self.listenFor(NotificationType.PaymentContextChanged, action: #selector(refreshPayment), object: nil)
        
        stripeService.loadPayment(host: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func configure() {
        self.refreshPayment()
    }
    
    func refreshPayment() {
        guard let paymentContext = stripeService.paymentContext else { return }
        if paymentContext.loading {
            self.activityIndicator.startAnimating()
            self.paymentLabel.text = "Loading your payment methods"
            self.constraintIconWidth.constant = 40
            
            canAddPayment = false
        }
        else if let paymentMethod = paymentContext.selectedPaymentMethod {
            self.activityIndicator.stopAnimating()
            
            self.paymentLabel.text = paymentMethod.label
            self.paymentIcon.image = paymentMethod.image
            self.constraintIconWidth.constant = 60
            
            canAddPayment = false
            
            // always write card to firebase since it's an internal call
            stripeService.savePaymentInfo(paymentMethod)
        }
        else {
            self.activityIndicator.stopAnimating()
            self.paymentLabel.text = "Click to add a payment method"
            self.constraintIconWidth.constant = 0
            
            canAddPayment = true
        }
    }
}
