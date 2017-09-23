//
//  PaymentInfoViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 9/21/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Stripe

class PaymentInfoViewController: UIViewController {
    
    @IBOutlet weak var paymentButton: UIButton!
    @IBOutlet weak var paymentIcon: UIImageView!
    @IBOutlet weak var paymentLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var constraintIconWidth: NSLayoutConstraint!
    
    let stripeService = StripeService()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.listenFor(NotificationType.PaymentContextChanged, action: #selector(refreshPayment), object: nil)
        
        stripeService.loadPayment(host: self)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didClickAddPayment(_ sender: UIButton) {
        stripeService.paymentContext?.presentPaymentMethodsViewController()
    }
}

// MARK: - Listeners for STPPaymentContext
extension PaymentInfoViewController {
    func refreshPayment() {
        guard let paymentContext = stripeService.paymentContext else { return }
        if paymentContext.loading {
            self.activityIndicator.startAnimating()
            self.paymentLabel.text = "Loading your payment methods"
            self.constraintIconWidth.constant = 60
            
            self.paymentButton.isEnabled = false
        }
        else if let paymentMethod = paymentContext.selectedPaymentMethod {
            self.activityIndicator.stopAnimating()
            
            self.paymentLabel.text = paymentMethod.label
            self.paymentIcon.image = paymentMethod.image
            self.constraintIconWidth.constant = 60
            
            self.paymentButton.isEnabled = false
        }
        else {
            self.activityIndicator.stopAnimating()
            self.paymentLabel.text = "Click to add a payment method"
            self.constraintIconWidth.constant = 0
            
            self.paymentButton.isEnabled = true
        }
    }
}
