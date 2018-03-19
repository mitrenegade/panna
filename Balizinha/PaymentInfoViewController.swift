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
    
    var viewModel: PaymentViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.listenFor(NotificationType.PaymentContextChanged, action: #selector(refreshPayment), object: nil)
//        StripeService.shared.hostController = self
        StripeService.shared.status.asObservable().subscribe(onNext: { status in
            self.viewModel = PaymentViewModel(status: status)
        })
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didClickAddPayment(_ sender: UIButton) {
        if viewModel?.canAddPayment == true {
            LoggingService.shared.log(event: LoggingEvent.show_payment_controller, info: nil)
            StripeService.shared.paymentContext.value?.presentPaymentMethodsViewController()
        }
    }
}

// MARK: - Listeners for STPPaymentContext
extension PaymentInfoViewController {
    @objc func refreshPayment() {
        guard let viewModel = viewModel else { return }
        self.paymentLabel.text = viewModel.labelTitle
        self.constraintIconWidth.constant = viewModel.iconWidth
        self.paymentIcon.image = viewModel.icon
        if viewModel.activityIndicatorShouldAnimate {
            self.activityIndicator.startAnimating()
        }
        else {
            self.activityIndicator.stopAnimating()
        }

        if let paymentMethod = StripeService.shared.paymentContext.value?.selectedPaymentMethod {
            // always write card to firebase since it's an internal call
            print("updated card")
            PaymentService.savePaymentInfo(paymentMethod)
        }
    }
}
