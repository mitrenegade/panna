//
//  AddPaymentViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 10/10/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

protocol AddPaymentDelegate {
    func needsRefreshPaymentMethods()
}

class AddPaymentViewController: UIViewController {
    var stripeService: StripeService = StripeService()
    var delegate: AddPaymentDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.listenFor(NotificationType.PaymentContextChanged, action: #selector(refreshPayment), object: nil)

        stripeService.loadPayment(host: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func refreshPayment() {
        guard let paymentContext = stripeService.paymentContext else { return }
        if paymentContext.loading {
            print("started loading")
            stripeService.paymentContext?.presentPaymentMethodsViewController()
        }
        else if paymentContext.selectedPaymentMethod == nil {
            print("done loading; no payment")
            self.navigationController?.popViewController(animated: true)
        }
        else if let paymentMethod = paymentContext.selectedPaymentMethod {
            // always write card to firebase since it's an internal call
            print("added card")
            stripeService.savePaymentInfo(paymentMethod)
            delegate?.needsRefreshPaymentMethods()
        }
    }
}
