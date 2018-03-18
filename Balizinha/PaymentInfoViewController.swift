//
//  PaymentInfoViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 9/21/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Stripe
import Firebase

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
        stripeService.hostController = self
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didClickAddPayment(_ sender: UIButton) {
        let viewModel = PaymentViewModel(paymentContext: stripeService.paymentContext)
        if viewModel.canAddPayment {
            LoggingService.shared.log(event: LoggingEvent.show_payment_controller, info: nil)
            stripeService.paymentContext?.presentPaymentMethodsViewController()
        }
    }
}

// MARK: - Listeners for STPPaymentContext
extension PaymentInfoViewController {
    @objc func refreshPayment() {
        let viewModel = PaymentViewModel(paymentContext: stripeService.paymentContext)
        self.paymentLabel.text = viewModel.labelTitle
        self.constraintIconWidth.constant = viewModel.iconWidth
        self.paymentIcon.image = viewModel.icon
        if viewModel.activityIndicatorShouldAnimate {
            self.activityIndicator.startAnimating()
        }
        else {
            self.activityIndicator.stopAnimating()
        }

        if let paymentMethod = stripeService.paymentContext?.selectedPaymentMethod {
            // always write card to firebase since it's an internal call
            print("updated card")
            PaymentService.savePaymentInfo(paymentMethod)
        }
    }
}
