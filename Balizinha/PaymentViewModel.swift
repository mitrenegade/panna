//
//  PaymentViewModel.swift
//  Balizinha
//
//  Created by Bobby Ren on 10/11/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Stripe

class PaymentViewModel: NSObject {
    let paymentContext: STPPaymentContext?
    var privacy: Bool = false
    init(paymentContext: STPPaymentContext?, privacy: Bool = false) {
        self.paymentContext = paymentContext
        self.privacy = privacy
    }
    
    var labelTitle: String {
        if paymentContext?.loading == true {
            return "Loading your payment methods"
        }
        else if let method = paymentContext?.selectedPaymentMethod {
            if privacy {
                return "Click to view payment methods"
            }
            else {
                return "Payment method: \(method.label)"
            }
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
    
    var icon: UIImage? {
        guard let method = paymentContext?.selectedPaymentMethod else { return nil }
        return method.image
    }
}
