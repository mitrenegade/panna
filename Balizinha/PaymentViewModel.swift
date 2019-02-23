//
//  PaymentViewModel.swift
//  Balizinha
//
//  Created by Bobby Ren on 10/11/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Stripe
import RenderPay

class PaymentViewModel: NSObject {
    let status: PaymentStatus
    var privacy: Bool = false
    init(status: PaymentStatus, privacy: Bool = false) {
        self.status = status
        self.privacy = privacy
    }
    
    var labelTitle: String {
        switch status {
        case .loading:
            return "Loading your payment methods"
        case .ready(let paymentMethod):
            guard let method = paymentMethod else {
                return "Click to add a payment method"
            }
            
            if privacy {
                return "Click to view payment methods"
            }
            else {
                return "Payment method: \(method.label)"
            }
        case .noPaymentMethod:
            return "Click to add a payment method"
        case .noCustomer:
            // this will happen if stripeCustomers was not created correctly at time of user signup, or if it was somehow deleted
            return "Click to enable payments"
        }
    }
    
    var iconWidth: CGFloat {
        switch status {
        case .noPaymentMethod, .noCustomer:
            return 0
        case .loading:
            return 40
        case .ready(let paymentMethod):
            if paymentMethod != nil {
                return 60
            }
            return 0
        }
    }
    
    var activityIndicatorShouldAnimate: Bool {
        return status == PaymentStatus.loading
    }
    
    var canAddPayment: Bool {
        return !(status == .loading || status == .noCustomer)
    }
    
    var needsValidateCustomer: Bool {
        return status == .noCustomer
    }
    
    var icon: UIImage? {
        switch status {
        case .ready(let paymentMethod):
            guard let method = paymentMethod else { return nil }
            return method.image
        default:
            return nil
        }
    }
}
