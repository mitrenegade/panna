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
    var paymentContext: STPPaymentContext?
    
    @IBOutlet weak var paymentButton: UIButton!
    @IBOutlet weak var paymentIcon: UIImageView!
    @IBOutlet weak var paymentLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var constraintIconWidth: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let customerContext = STPCustomerContext(keyProvider: StripeService.shared)
        self.paymentContext = STPPaymentContext(customerContext: customerContext)
        self.paymentContext?.delegate = self
        self.paymentContext?.hostViewController = self
        self.paymentContext?.paymentAmount = 500 // pull from game object
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didClickButton(sender: UIButton) {
        self.paymentContext?.presentPaymentMethodsViewController()
    }
}

extension PaymentInfoViewController: STPPaymentContextDelegate {
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        print("didChange")
        self.paymentButton.isEnabled = paymentContext.selectedPaymentMethod != nil

        if paymentContext.loading {
            self.activityIndicator.startAnimating()
            self.paymentLabel.text = "Loading your payment methods"
            self.constraintIconWidth.constant = 60
        }
        else {
            self.activityIndicator.stopAnimating()
            if let paymentMethod = paymentContext.selectedPaymentMethod {
                self.paymentLabel.text = paymentContext.selectedPaymentMethod?.label
                self.paymentIcon.image = paymentContext.selectedPaymentMethod?.image
                self.constraintIconWidth.constant = 60
            }
            else {
                self.paymentLabel.text = "Click to add a payment method"
                self.constraintIconWidth.constant = 0
            }
        }
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext,
                        didCreatePaymentResult paymentResult: STPPaymentResult,
                        completion: @escaping STPErrorBlock) {
        print("didCreatePayment")
//        FirebaseFunctionsService.createCharge(paymentResult.source.stripeID, completion: { (error: Error?) in
//            if let error = error {
//                completion(error)
//            } else {
//                completion(nil)
//            }
//        })
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext,
                        didFinishWith status: STPPaymentStatus,
                        error: Error?) {
        print("didFinish")
        switch status {
        case .error: break
//            self.showError(error)
        case .success: break
//            self.showReceipt()
        case .userCancellation:
            return // Do nothing
        }
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext,
                        didFailToLoadWithError error: Error) {
        self.navigationController?.popViewController(animated: true)
        print("didFailToLoad")
        // Show the error to your user, etc.
    }
}
